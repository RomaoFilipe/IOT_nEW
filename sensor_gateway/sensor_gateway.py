import os
import json
import time
import paho.mqtt.client as mqtt
import requests

# 🌐 Configurações
MQTT_BROKER = os.getenv("MQTT_BROKER", "mqtt")
MQTT_PORT = int(os.getenv("MQTT_PORT", 1883))
MQTT_TOPIC = "sensors/data"

API_URL = os.getenv("API_URL", "http://host.docker.internal:3000/api/sensors")
API_TOKEN = os.getenv("API_TOKEN", "abc123supersecreto")

HEADERS = {
    "Authorization": f"Bearer {API_TOKEN}",
    "Content-Type": "application/json"
}

# 🔌 Quando conecta ao broker
def on_connect(client, userdata, flags, rc):
    if rc == 0:
        print("✅ Ligado ao broker MQTT")
        client.subscribe(MQTT_TOPIC)
    else:
        print("❌ Erro ao ligar ao MQTT:", rc)

# 📦 Quando recebe mensagem
def on_message(client, userdata, msg):
    try:
        payload = json.loads(msg.payload.decode())
        device_id = payload.get("device_id")
        print(f"📦 Recebido do dispositivo {device_id}: {payload}")

        if not device_id:
            print("⚠️ Payload sem device_id")
            return

        # 🔍 Identificar sensor (enviando sensor_type!)
        identify = requests.get(f"{API_URL}/identify", params={
            "device_id": device_id,
            "sensor_type": payload.get("sensor_type")  # 👈 Atualiza tipo no backend
        })

        if identify.status_code != 200:
            print("❌ Erro ao identificar sensor:", identify.status_code)
            return

        sensor_data = identify.json()
        sensor_id = sensor_data.get("id")

        if not sensor_id:
            print("❌ Sensor não pôde ser identificado")
            return

        # ⚙️ Se for sensor de irrigação, só identifica
        if payload.get("sensor_type") == "irrigation":
            print(f"💧 Sensor de irrigação identificado: {sensor_id} (sem envio de leitura)")
            return

        # ✅ Enviar leitura para sensores normais
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
    client = mqtt.Client()
    client.on_connect = on_connect
    client.on_message = on_message

    client.connect(MQTT_BROKER, MQTT_PORT, 60)
    client.loop_forever()

if __name__ == "__main__":
    main()
