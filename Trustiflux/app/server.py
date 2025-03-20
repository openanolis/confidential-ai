from http.server import SimpleHTTPRequestHandler
from socketserver import TCPServer
import json
import datetime
import os

PORT = 8000
MODEL_DIR = "/app/model/"  # 根目录路径

class Handler(SimpleHTTPRequestHandler):
    def do_GET(self):
        try:
            file_list = []
            
            # 使用 os.walk 递归遍历目录
            for root, dirs, files in os.walk(MODEL_DIR):
                # 计算相对路径
                relative_root = os.path.relpath(root, MODEL_DIR)
                
                # 处理当前目录文件
                for file in files:
                    if relative_root == ".":
                        full_path = file
                    else:
                        full_path = os.path.join(relative_root, file)
                    file_list.append(full_path)

            response = {
                "timestamp": datetime.datetime.now().isoformat(),
                "total_files": len(file_list),
                "files": sorted(file_list)  # 排序便于查看
            }

            self.send_json(response)

        except Exception as e:
            self.send_error(500, f"Error: {str(e)}")

    def send_json(self, data):
        self.send_response(200)
        self.send_header("Content-type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps(data, indent=2).encode())

if __name__ == "__main__":
    with TCPServer(("", PORT), Handler) as httpd:
        print(f"Serving on port {PORT}")
        httpd.serve_forever()
