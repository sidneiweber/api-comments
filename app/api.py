from flask import Flask
from flask import jsonify
from flask import request
from prometheus_flask_exporter import PrometheusMetrics

app_name = 'comentarios'
app = Flask(app_name)
metrics = PrometheusMetrics(app)
app.debug = True
comments = {}

def all_required_services_are_running():
    return True
@app.route('/health')
def health():
    if all_required_services_are_running():
        return 'OK', 200
    else:
        return 'Service Unavailable', 500

@app.route('/api/comment/new', methods=['POST'])
def api_comment_new():
    request_data = request.get_json()

    email = request_data['email']
    comment = request_data['comment']
    content_id = '{}'.format(request_data['content_id'])

    new_comment = {
            'email': email,
            'comment': comment,
            }

    if content_id in comments:
        comments[content_id].append(new_comment)
    else:
        comments[content_id] = [new_comment]

    message = 'comment created and associated with content_id {}'.format(content_id)
    response = {
            'status': 'SUCCESS',
            'message': message,
            }
    return jsonify(response)

@app.route('/api/comment/list/<content_id>')
def api_comment_list(content_id):
    content_id = '{}'.format(content_id)

    if content_id in comments:
        return jsonify(comments[content_id])
    else:
        message = 'content_id {} not found'.format(content_id)
        response = {
                'status': 'NOT-FOUND',
                'message': message,
                }
        return jsonify(response), 404
