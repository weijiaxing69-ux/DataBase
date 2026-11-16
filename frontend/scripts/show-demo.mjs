// 可见浏览器演示：node scripts/show-demo.mjs；关闭浏览器后关闭本脚本启动的服务。
import { chromium, expect } from '@playwright/test'
import { spawn } from 'node:child_process'
import { fileURLToPath } from 'node:url'
import path from 'node:path'

const frontend = fileURLToPath(new URL('../', import.meta.url))
const root = path.dirname(frontend.replace(/[\\/]$/, ''))
const servers = []
async function ready(url) {
  try { return (await fetch(url)).ok } catch { return false }
}
async function start(url, command, args, cwd) {
  if (await ready(url)) return
  const child = spawn(command, args, { cwd, windowsHide: true, stdio: 'ignore' })
  servers.push(child)
  child.on('error', error => console.error(error.message))
  for (let i = 0; i < 100; i++) {
    if (await ready(url)) return
    if (child.exitCode !== null) throw new Error(`服务启动失败：${url}`)
    await new Promise(resolve => setTimeout(resolve, 300))
  }
  throw new Error(`服务启动超时：${url}`)
}
let browser
try {
  await start('http://127.0.0.1:8001/docs', path.join(root, '.venv/Scripts/python.exe'),
    ['-m', 'uvicorn', 'app.demo:create_app', '--factory', '--host', '127.0.0.1', '--port', '8001'], path.join(root, 'backend'))
  await start('http://127.0.0.1:5173', process.execPath,
    [path.join(frontend, 'node_modules/vite/bin/vite.js'), '--host', '127.0.0.1', '--port', '5173', '--strictPort'], frontend)
  browser = await chromium.launch({ headless: false, slowMo: 650, args: ['--start-maximized'] })
  const context = await browser.newContext({ viewport: null })
  const page = await context.newPage()
  const pause = ms => page.waitForTimeout(ms)
  async function explain(text, ms = 3000) {
    console.log(text)
    await page.evaluate(text => {
      let tip = document.getElementById('demo-explanation')
      if (!tip) {
        tip = document.createElement('div'); tip.id = 'demo-explanation'
        tip.style.cssText = 'position:fixed;bottom:20px;left:50%;transform:translateX(-50%);z-index:99999;background:#163f32;color:white;padding:16px 24px;border-radius:10px;font:18px Microsoft YaHei;box-shadow:0 4px 20px #0004;max-width:85vw;pointer-events:none;'
        document.body.append(tip)
      }
      tip.textContent = text
    }, text)
    await pause(ms)
  }
  async function login(username) {
    await page.getByLabel('账号', { exact: true }).fill(username)
    await page.getByLabel('密码', { exact: true }).fill('Demo123!')
    await page.getByRole('button', { name: '登录', exact: true }).click()
    await expect(page.getByRole('button', { name: '退出登录' })).toBeVisible()
  }
  async function nav(name) {
    await page.getByRole('navigation').getByRole('button', { name, exact: true }).click()
    await expect(page.getByText('正在加载…')).toHaveCount(0)
  }
  async function click(name) {
    await page.getByRole('button', { name, exact: true }).click()
  }
  await page.goto('http://127.0.0.1:5173')
  await page.bringToFront()
  await explain('第1步：管理员登录。所有操作都使用独立演示数据。')
  await login('platform_admin')
  for (const name of ['运营商', '场站', '充电桩', '充电枪']) {
    await nav(name)
    await explain(`查看${name}列表，数据来自后端接口。`)
  }
  await page.getByRole('button', { name: '详情', exact: true }).first().click()
  await explain('这里查看充电枪详情：所属桩、功率、状态和故障标记。')
  await click('关闭')
  await click('退出登录')
  await explain('第2步：切换运维工程师，只能查看授权场站的设备。')
  await login('maintenance_engineer')
  await nav('充电桩')
  await explain('工程师只能看到场站1的设备；设备档案修改需要提交申请。')
  await nav('变更申请')
  await click('新增变更申请')
  await page.getByLabel('目标桩编号（桩或枪选填一个）', { exact: true }).fill('1')
  await page.getByLabel('拟修改内容（JSON对象）', { exact: true }).fill('{"model_name":"浏览器演示新型号"}')
  const reason = `可见浏览器演示-${Date.now()}`
  await page.getByLabel('申请理由', { exact: true }).fill(reason)
  await explain('提交对1号桩的型号修改申请；工程师不能审批自己的申请。')
  await click('保存')
  await expect(page.getByRole('dialog')).toHaveCount(0)
  await pause(2000)
  await click('退出登录')
  await login('platform_admin')
  await nav('变更申请')
  await explain('第3步：管理员审批工程师的申请。')
  await page.getByRole('row').filter({ hasText: reason }).getByRole('button', { name: '审批', exact: true }).click()
  await page.getByLabel('审批意见', { exact: true }).fill('同意，演示档案修改')
  await click('提交审批')
  await expect(page.getByRole('dialog')).toHaveCount(0)
  await nav('充电桩')
  await expect(page.locator('tbody')).toContainText('浏览器演示新型号')
  await explain('审批已生效：1号桩的设备型号已经更新。')
  await nav('设备验收')
  await click('新增设备验收')
  await page.getByLabel('充电桩编号', { exact: true }).fill('1')
  for (const name of ['协议联调通过', '铭牌核对通过', '启停测试通过', '心跳测试通过']) await page.getByLabel(name, { exact: true }).check()
  await explain('第4步：四项验收全部通过，后端才会允许设备投运。')
  await click('保存')
  await expect(page.getByRole('dialog')).toHaveCount(0)
  await nav('设备联调')
  await click('签发一小时凭据')
  await expect(page.getByLabel('设备凭据', { exact: true })).not.toHaveValue('')
  await click('发送心跳')
  await expect(page.locator('pre')).toContainText('"received": true')
  await explain('第5步：心跳已收到。等待正常采样窗口，再复核恢复。', 1000)
  for (let remaining = 32; remaining > 0; remaining -= 4) await explain(`正在形成正常采样窗口，还需约${remaining}秒……`, 4000)
  await click('发送心跳')
  await click('复核恢复')
  await expect(page.locator('pre')).toContainText('"recovered": true')
  await explain('恢复复核通过：设备已在线，充电枪恢复空闲。')
  await click('创建订单并启动')
  await expect(page.getByLabel('订单编号', { exact: true })).not.toHaveValue('')
  await explain('第6步：模拟订单已创建，占用充电枪，启动命令进入发送队列。')
  await click('发送下一条命令')
  await expect(page.locator('pre')).toContainText('"processed": true')
  await nav('设备命令')
  await explain('启动命令已由模拟设备确认，命令状态为成功。')
  await nav('设备联调')
  await click('结束订单')
  await click('发送下一条命令')
  await nav('充电枪')
  await explain('第7步：结束订单、发送停止命令后，1号枪恢复空闲。')
  await nav('状态历史')
  await explain('演示完成：这里记录离线→空闲→占用→空闲的变化。浏览器保持打开，你可以继续操作。', 5000)
  console.log('DEMO_COMPLETE: 浏览器保持打开；关闭窗口后退出演示服务。')
} catch (error) {
  console.error('演示中断：', error)
}
// 保持可见浏览器和演示服务，用户可以继续在页面操作。
if (browser?.isConnected()) await new Promise(resolve => browser.on('disconnected', resolve))
for (const child of servers) child.kill()
