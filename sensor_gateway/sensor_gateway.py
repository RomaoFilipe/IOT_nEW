import os
import json
import time
import paho.mqtt.client as mqtt
import requests
from datetime import datetime

# 🌐 Configurações
MQTT_BROKER = os.getenv("MQTT_BROKER", "mqtt")
MQTT_PORT = int(os.getenv("MQTT_PORT", 1883))
MQTT_TOPIC = "sensors/data"

API_URL = os.getenv("API_URL", "http://172.31.24.78:3000/api/sensors")
API_TOKEN = os.getenv("API_TOKEN", "abc123supersecreto")

HEADERS = {
    "Authorization": f"Bearer {API_TOKEN}",
    "Content-Type": "application/json"
}

# 🔌 Quando conecta ao broker
def on_connect(client, userdata, flags, reason_code, properties):
    if reason_code == 0:
        print("✅ Ligado ao broker MQTT (v5)")
        client.subscribe(MQTT_TOPIC)
    else:
        print(f"❌ Erro ao ligar ao MQTT (v5): {reason_code}")

# 📦 Quando recebe mensagem
def on_message(client, userdata, msg):
    try:
        payload = json.loads(msg.payload.decode())
        device_id = payload.get("device_id")
        print(f"📦 Recebido do dispositivo {device_id}: {payload}")

        if not device_id:
            print("⚠️ Payload sem device_id")
            return

        # 🔍 Identificar sensor
        identify = requests.get(f"{API_URL}/identify", params={
            "device_id": device_id,
            "sensor_type": payload.get("sensor_type")
        })

        if identify.status_code != 200:
            print("❌ Erro ao identificar sensor:", identify.status_code)
            return

        sensor_data = identify.json()
        sensor_id = sensor_data.get("id")

        if not sensor_id:
            print("❌ Sensor não pôde ser identificado")
            return

        # 💧 Sensor de irrigação
        if payload.get("sensor_type") == "irrigation":
            # ✅ Atualizar status do sensor (irrigando/parado)
            update_url = f"{API_URL}/{sensor_id}"
            update_payload = { "status": payload.get("status") }

            status_update = requests.patch(update_url, json=update_payload, headers=HEADERS, timeout=5)
            if status_update.status_code == 200:
                print(f"✅ Status do sensor atualizado para '{payload.get('status')}'")
            else:
                print(f"⚠️ Erro ao atualizar status: {status_update.status_code}")

            # ✅ Enviar log de execução
            if "duration" in payload and "status" in payload:
                log_url = "http://172.31.24.78:3000/api/irrigation_logs"
                executed_time = datetime.utcfromtimestamp(payload.get("timestamp", time.time()))
                irrigation_payload = {
                    "device_id": device_id,
                    "duration": payload["duration"],
                    "status": payload["status"],
                    "executed_at": executed_time.isoformat()
                }
                response = requests.post(log_url, json=irrigation_payload, headers=HEADERS, timeout=5)
                if response.status_code == 201:
                    print(f"💧 Log de irrigação registado com sucesso para Sensor #{sensor_id}")
                else:
                    print(f"⚠️ Erro ao enviar log de irrigação: {response.status_code} - {response.text}")
            else:
                print(f"💧 Sensor de irrigação identificado: {sensor_id} (sem log de execução)")
            return

        # ✅ Sensor normal - leitura
        readings_url = f"{API_URL}/{sensor_id}/readings"
        response = requests.post(readings_url, json=payload, headers=HEADERS, timeout=5)

        if response.status_code == 201:
            print(f"🔁 Leitura enviada com sucesso para Sensor #{sensor_id}")
        else:
            print(f"⚠️ Erro ao enviar leitura: {response.status_code} - {response.text}")

    except Exception as e:
        print("❌ Erro ao processar mensagem:", e)

# 🚀 Inicialização
def main():
    print("🚀 Sensor Gateway a iniciar...")
    client = mqtt.Client(protocol=mqtt.MQTTv5)
    client.on_connect = on_connect
    client.on_message = on_message
    client.connect(MQTT_BROKER, MQTT_PORT, 60)
    client.loop_forever()

if __name__ == "__main__":
    main()
