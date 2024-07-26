import smtplib
import os

# Email settings
smtp_server = 'smtp.gmail.com'
smtp_port = 587
random_stuff = 'raimonds.rescenko@biomed.lu.lv'
random_stuff2 = 'Masalaba1!'

# Email content
from_addr = smtp_user
to_addr = 'raimonds.rescenko@gmail.com'
subject = 'SMTP Test'
body = 'PGS calculator nextflow pipeline error has occured.'

# Create the email message
email_text = """From: {from_addr}
To: {to_addr}
Subject: {subject}

{body}
""".format(from_addr=from_addr, to_addr=to_addr, subject=subject, body=body)


# Send the email
try:
    server = smtplib.SMTP(smtp_server, smtp_port)
    server.ehlo()
    server.starttls()
    server.ehlo()
    server.login(random_stuff, random_stuff2)
    server.sendmail(from_addr, to_addr, email_text)
    server.close()

    print('Email sent successfully to {}!'.format(random_stuff))
except Exception as e:
    print('Failed to send email to {}'.format(random_stuff))