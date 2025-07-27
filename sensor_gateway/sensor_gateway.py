import os
import json
import time
import requests
from datetime import datetime
import paho.mqtt.client as mqtt
from paho.mqtt.client import Client, CallbackAPIVersion

# 🌐 Variáveis de ambiente
MQTT_BROKER = os.getenv("MQTT_BROKER", "mqtt")
MQTT_PORT = int(os.getenv("MQTT_PORT", 1883))
MQTT_TOPIC = "sensors/data"
API_URL = os.getenv("API_URL", "http://localhost:3000/api/sensors")
API_TOKEN = os.getenv("API_TOKEN", "abc123supersecreto")

HEADERS = {
    "Authorization": f"Bearer {API_TOKEN}",
    "Content-Type": "application/json"
}

# 🔌 Callback de ligação
def on_connect(client, userdata, flags, reason_code, properties=None):
    if reason_code == 0:
        print("✅ Ligado ao broker MQTT (v5)")
        client.subscribe(MQTT_TOPIC)
        print(f"📡 Subscrito no tópico: {MQTT_TOPIC}")
    else:
        print(f"❌ Erro na ligação MQTT: Código {reason_code}")

# 📩 Callback ao receber mensagem
def on_message(client, userdata, msg):
    try:
        payload = json.loads(msg.payload.decode())
        device_id = payload.get("device_id")
        print(f"📦 Mensagem recebida de {device_id}: {payload}")

        if not device_id:
            print("⚠️ Mensagem sem device_id")
            return

        # Identificar o sensor
        identify = requests.get(f"{API_URL}/identify", params={
            "device_id": device_id,
            "sensor_type": payload.get("sensor_type")
        })

        if identify.status_code != 200:
            print(f"❌ Sensor não encontrado: {identify.status_code}")
            return

        sensor_data = identify.json()
        sensor_id = sensor_data.get("id")
        if not sensor_id:
            print("❌ ID do sensor não foi retornado")
            return

        # Sensor de irrigação → atualização de estado + log
        if payload.get("sensor_type") == "irrigation":
            update_url = f"{API_URL}/{sensor_id}"
            update_payload = { "status": payload.get("status") }

            status_update = requests.patch(update_url, json=update_payload, headers=HEADERS, timeout=5)
            if status_update.status_code == 200:
                print(f"✅ Estado atualizado para '{payload.get('status')}'")
            else:
                print(f"⚠️ Falha ao atualizar estado: {status_update.status_code}")

            if "duration" in payload and "status" in payload:
                log_url = f"{API_URL.replace('/sensors', '')}/irrigation_logs"
                executed_time = datetime.utcfromtimestamp(payload.get("timestamp", time.time()))
                irrigation_payload = {
                    "device_id": device_id,
                    "duration": payload["duration"],
                    "status": payload["status"],
                    "executed_at": executed_time.isoformat()
                }
                response = requests.post(log_url, json=irrigation_payload, headers=HEADERS, timeout=5)
                if response.status_code == 201:
                    print(f"💧 Log de irrigação registado com sucesso")
                else:
                    print(f"⚠️ Falha ao registar irrigação: {response.status_code} - {response.text}")
            return

        # Sensor normal → leitura
        readings_url = f"{API_URL}/{sensor_id}/readings"
        response = requests.post(readings_url, json=payload, headers=HEADERS, timeout=5)
        if response.status_code == 201:
            print(f"📊 Leitura registada para Sensor #{sensor_id}")
        else:
            print(f"⚠️ Erro ao enviar leitura: {response.status_code} - {response.text}")

    except Exception as e:
        print(f"❌ Erro ao processar mensagem: {e}")

# 🚀 Função principal
def main():
    print("🚀 Sensor Gateway a iniciar...")
    try:
        client = Client(
            CallbackAPIVersion.V1,               # ✅ Ordem POSICIONAL
            client_id="sensor_gateway",
            protocol=mqtt.MQTTv5
        )
        client.on_connect = on_connect
        client.on_message = on_message
        client.connect(MQTT_BROKER, MQTT_PORT, keepalive=60)
        print("✅ Conectado. A ouvir mensagens MQTT...")
        client.loop_forever()
    except Exception as e:
        print(f"❌ Erro no main(): {e}")

# ▶️ Ponto de entrada
if __name__ == "__main__":
    print("📥 A correr como script principal")
    main()
