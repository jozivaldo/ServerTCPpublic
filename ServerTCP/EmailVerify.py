import logging
from waitress import serve
from flask import Flask, request, jsonify
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import os
import time

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024

@app.route('/send_email', methods=['POST'])
def send_email():
    data = request.json
    to_email = data.get('to_email')
    subject = data.get('subject')
    body = data.get('body')

    from_email = os.getenv('EMAIL_USER')
    password = os.getenv('EMAIL_PASSWORD')

    try:
        msg = MIMEMultipart()
        msg['From'] = from_email
        msg['To'] = to_email
        msg['Subject'] = subject
        msg.attach(MIMEText(body, 'plain'))

        server = smtplib.SMTP('smtp.gmail.com', 587)
        server.starttls()
        server.login(from_email, password)
        server.sendmail(from_email, to_email, msg.as_string())
        server.quit()

        return jsonify({"success": True, "message": "E-mail enviado com sucesso!"}), 200
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500

mode = "dev"

if __name__ == '__main__':
    if mode == 'prod':
        logger.info("Iniciando servidor em produção com Waitress...")
        serve(app, host='0.0.0.0', port=5000, threads=4)
    else:
        app.run(host='127.0.0.1', port=5000, debug=True)

    while True:
        time.sleep(1)