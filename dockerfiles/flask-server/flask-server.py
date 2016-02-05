import sys
from flask import Flask, request
app = Flask(__name__)

@app.route('/')
def hello():
    s_dn = request.environ.get('HTTP_SSL_CLIENT_S_DN')
    if s_dn:
        name = dict([x.split('=') for x in s_dn.split('/')[1:]])['CN']
        return 'Hello {}!\n'.format(name)
    else:
        return "Hello Unauthorized!"
    
if __name__ == "__main__":
    app.run(host="0.0.0.0", debug=True)
