#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <HTTPClient.h>
#include <WiFiManager.h>

// DHT libraries
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

const unsigned long sendIntervalMs = 10000; // safer than 2s

unsigned long lastSendAt = 0;
unsigned long lastReconnectAttempt = 0;
unsigned long wifiLostTime = 0;

// ---------------- WIFI EVENTS ----------------
void WiFiEvent(WiFiEvent_t event) {
  switch (event) {

    case ARDUINO_EVENT_WIFI_STA_START:
      Serial.println("WiFi started");
      break;

    case ARDUINO_EVENT_WIFI_STA_CONNECTED:
      Serial.println("Connected to WiFi AP");
      break;

    case ARDUINO_EVENT_WIFI_STA_GOT_IP:
      Serial.print("IP Address: ");
      Serial.println(WiFi.localIP());
      wifiLostTime = 0;
      break;

    case ARDUINO_EVENT_WIFI_STA_DISCONNECTED:
      Serial.println("WiFi disconnected");
      break;

    default:
      break;
  }
}

// ---------------- WIFI PORTAL CALLBACKS ----------------
void notifySetupPortalStarted(WiFiManager* manager) {
  (void)manager;
  Serial.println();
  Serial.println("WiFi setup portal started.");
  Serial.print("Connect to: ");
  Serial.println(setupPortalName);
  Serial.println("Open: http://192.168.4.1");
}

void notifyWiFiSaved() {
  Serial.println("WiFi credentials saved.");
}

// ---------------- WIFI SETUP ----------------
void setupWiFi() {
  WiFi.mode(WIFI_STA);

  WiFi.setAutoReconnect(true);
  WiFi.persistent(true);

  WiFi.onEvent(WiFiEvent);

  WiFiManager wifiManager;
  wifiManager.setDebugOutput(true);
  wifiManager.setAPCallback(notifySetupPortalStarted);
  wifiManager.setSaveConfigCallback(notifyWiFiSaved);
  wifiManager.setConfigPortalTimeout(180);
  wifiManager.setConnectTimeout(20);
  wifiManager.setConnectRetries(3);

  Serial.println("Connecting to saved WiFi...");

  if (!wifiManager.autoConnect(setupPortalName)) {
    Serial.println("WiFi setup failed. Restarting...");
    delay(2000);
    ESP.restart();
  }

  Serial.println("WiFi connected.");
  Serial.print("IP address: ");
  Serial.println(WiFi.localIP());
}

// ---------------- WIFI SAFE RECONNECT ----------------
bool ensureWiFiConnected() {
  if (WiFi.status() == WL_CONNECTED) {
    wifiLostTime = 0;
    return true;
  }

  if (wifiLostTime == 0) {
    wifiLostTime = millis();
    Serial.println("WiFi lost. Starting recovery timer...");
  }

  // restart if WiFi lost too long
  if (millis() - wifiLostTime > 60000) {
    Serial.println("WiFi lost for 60s. Restarting ESP32...");
    ESP.restart();
  }

  // reconnect every 10 seconds only
  if (millis() - lastReconnectAttempt > 10000) {
    lastReconnectAttempt = millis();

    Serial.println("Attempting safe WiFi reconnect...");
    WiFi.disconnect(false);
    delay(200);
    WiFi.reconnect();
  }

  return false;
}

// ---------------- SUPABASE SEND ----------------
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

  Serial.print("Failed HTTP ");
  Serial.print(responseCode);
  Serial.print(": ");
  Serial.println(responseBody);

  return false;
}

// ---------------- SETUP ----------------
void setup() {
  Serial.begin(115200);
  delay(1200);

  Serial.println("\nESP32 Sensor Starting...");

  dht.begin();

  setupWiFi();
}

// ---------------- LOOP ----------------
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
    Serial.println("Failed to read DHT11");
    return;
  }

  Serial.print("Temp: ");
  Serial.print(temperature);
  Serial.print("°C | Humidity: ");
  Serial.print(humidity);
  Serial.println("%");

  sendReading(temperature, humidity);
}