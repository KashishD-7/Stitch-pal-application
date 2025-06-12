import smtplib
import ssl
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

def send_otp_email(to_email, otp):
    smtp_server = 'smtp.gmail.com'
    smtp_port = 587
    smtp_user = 'sstichpal@gmail.com'
    smtp_password = 'otqlpuwfmaaoyzsf'

    subject = 'Your OTP Code'
    body = f'Your OTP is: {otp}'

    message = MIMEMultipart()
    message['From'] = 'sstichpal@gmail.com'
    message['To'] = to_email
    message['Subject'] = subject
    message.attach(MIMEText(body, 'plain'))

    # Create an unverified SSL context
    context = ssl._create_unverified_context()

    try:
        server = smtplib.SMTP(smtp_server, smtp_port)
        server.starttls(context=context)  # <-- Important: pass custom context here
        server.login(smtp_user, smtp_password)
        server.sendmail('no-reply@example.com', to_email, message.as_string())
        server.quit()
        print("OTP sent successfully!")
        return True
    except Exception as e:
        print(f"Error sending OTP: {e}")
        return False
