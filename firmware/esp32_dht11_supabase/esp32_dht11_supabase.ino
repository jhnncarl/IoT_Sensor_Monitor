#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <HTTPClient.h>
#include <WiFiManager.h>

// ✅ Required DHT libraries
#include "DHT.h"
#include "Adafruit_Sensor.h"

#define DHTPIN 4
#define DHTTYPE DHT11

DHT dht(DHTPIN, DHTTYPE);

// Supabase config
const char* supabaseInsertUrl =
    "https://xfumytkobyygaongyaax.supabase.co/rest/v1/sensor_readings";

const char* supabaseApiKey =
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhmdW15dGtvYnl5Z2Fvbmd5YWF4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODAwNDM4MzEsImV4cCI6MjA5NTYxOTgzMX0.Vumdgb2L7GiUbTG7RRKP2ua0ngyBukpfllnLe1gy3lU";

const char* setupPortalName = "ESP32-Sensor-Setup";
const unsigned long sendIntervalMs = 2000;

unsigned long lastSendAt = 0;
bool wasWiFiConnected = false;

// WiFi setup portal callback
void notifySetupPortalStarted(WiFiManager* manager) {
  (void)manager;
  Serial.println();
  Serial.println("WiFi setup portal started.");
  Serial.print("Connect to: ");
  Serial.println(setupPortalName);
  Serial.print("Then open: http://");
  Serial.println(WiFi.softAPIP());
}

void notifyWiFiSaved() {
  Serial.println("WiFi credentials saved. Connecting...");
}

void setupWiFi() {
  WiFi.mode(WIFI_STA);

  WiFiManager wifiManager;
  wifiManager.setAPCallback(notifySetupPortalStarted);
  wifiManager.setSaveConfigCallback(notifyWiFiSaved);
  wifiManager.setConfigPortalTimeout(180);

  Serial.println("Connecting to saved WiFi...");

  if (!wifiManager.autoConnect(setupPortalName)) {
    Serial.println("WiFi setup timed out. Restarting ESP32...");
    delay(2000);
    ESP.restart();
  }

  wasWiFiConnected = true;

  Serial.println("WiFi connected.");
  Serial.print("IP address: ");
  Serial.println(WiFi.localIP());
}

bool ensureWiFiConnected() {
  if (WiFi.status() == WL_CONNECTED) {
    if (!wasWiFiConnected) {
      wasWiFiConnected = true;
      Serial.println("WiFi reconnected.");
    }
    return true;
  }

  if (wasWiFiConnected) {
    wasWiFiConnected = false;
    Serial.println("WiFi disconnected. Reconnecting...");
  }

  WiFi.reconnect();
  delay(500);
  return WiFi.status() == WL_CONNECTED;
}

bool sendReading(float temperature, float humidity) {
  WiFiClientSecure client;
  client.setInsecure();

  HTTPClient http;

  if (!http.begin(client, supabaseInsertUrl)) {
    Serial.println("HTTPS begin failed.");
    return false;
  }

  String authHeader = "Bearer ";
  authHeader += supabaseApiKey;

  http.addHeader("Content-Type", "application/json");
  http.addHeader("apikey", supabaseApiKey);
  http.addHeader("Authorization", authHeader);
  http.addHeader("Prefer", "return=minimal");

  String payload = "{";
  payload += "\"temperature\":";
  payload += String(temperature, 1);
  payload += ",\"humidity\":";
  payload += String(humidity, 1);
  payload += "}";

  int responseCode = http.POST(payload);

  String responseBody = http.getString();
  http.end();

  if (responseCode == 201) {
    Serial.println("Data sent to Supabase successfully.");
    return true;
  }

  Serial.print("Failed. HTTP ");
  Serial.print(responseCode);
  Serial.print(": ");
  Serial.println(responseBody);

  return false;
}

void setup() {
  Serial.begin(115200);

  // Initialize DHT11
  dht.begin();

  setupWiFi();
}

void loop() {
  if (!ensureWiFiConnected()) {
    return;
  }

  unsigned long now = millis();
  if (now - lastSendAt < sendIntervalMs) {
    return;
  }
  lastSendAt = now;

  float humidity = dht.readHumidity();
  float temperature = dht.readTemperature();

  if (isnan(humidity) || isnan(temperature)) {
    Serial.println("Failed to read from DHT11 sensor.");
    return;
  }

  Serial.print("Temp: ");
  Serial.print(temperature);
  Serial.print("°C | Humidity: ");
  Serial.print(humidity);
  Serial.println("%");

  sendReading(temperature, humidity);
}