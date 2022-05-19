from flask import Flask, render_template, request

app = Flask(__name__)

@app.route('/', methods=['POST', 'GET'])
def main_post():
    return render_template('index.html', developer_name='Selcuk', not_valid=False)

if __name__ == '__main__':
    #app.run(debug=True)
    app.run(host='0.0.0.0', port=6161)