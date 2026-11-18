# 成员4会员前端

本目录实现 V1.4 中 membership 的 14 个 Vue 路由，页面通过 `src/api.js` 调用成员4 FastAPI 接口。

```powershell
npm install
npm run dev
```

默认开发服务器会将 `/api/v1` 请求代理到 `http://127.0.0.1:8000`；也可设置 `VITE_API_BASE_URL`。登录令牌只保存在当前浏览器 localStorage；服务端仍会逐请求校验账号状态、角色权限和资源归属。页面隐藏密文、哈希和令牌字段，并显示服务端返回的脱敏联系方式。
