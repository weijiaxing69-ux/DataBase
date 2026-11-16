import { defineConfig } from '@playwright/test'

// 两个服务都使用演示环境，测试不会连接用户的 MySQL。
export default defineConfig({
  testDir: './tests', workers: 1, timeout: 90000,
  use: { baseURL: 'http://127.0.0.1:5173', screenshot: 'only-on-failure', trace: 'retain-on-failure' },
  webServer: [
    { command: '..\\.venv\\Scripts\\python.exe -m uvicorn app.demo:create_app --factory --host 127.0.0.1 --port 8001', cwd: '../backend', url: 'http://127.0.0.1:8001/docs', reuseExistingServer: false },
    { command: 'npm.cmd run dev -- --port 5173 --strictPort', url: 'http://127.0.0.1:5173', reuseExistingServer: false },
  ],
})
