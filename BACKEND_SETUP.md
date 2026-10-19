# 琼史云端资料后台配置

本网站托管在 GitHub Pages，是静态网页。Supabase 提供共享数据库和管理员登录；浏览器使用的 `anon` / `publishable` key 不是管理员密码，数据库安全由行级安全策略（RLS）保护。**不要把 `service_role` key 放进网站。**

## 首次配置

1. 在 Supabase 创建项目。
2. 打开项目的 SQL Editor，执行仓库中的 `supabase-schema.sql`。
3. 在 Authentication 的 Providers / Sign-in 设置中关闭公开注册。通过 Authentication → Users 手动创建管理员邮箱和密码。
4. 在 SQL Editor 中把 `管理员用户 UUID` 替换为刚创建用户的 UUID，然后执行：

   ```sql
   insert into public.history_admins (user_id)
   values ('管理员用户 UUID');
   ```

5. 在 Supabase 项目设置中复制 Project URL 和 `anon` / `publishable` key，填入 `supabase-config.js`：

   ```js
   export const SUPABASE_URL = "https://你的项目.supabase.co";
   export const SUPABASE_ANON_KEY = "你的公开 anon 或 publishable key";
   ```

6. 提交并推送网站文件到 GitHub `main` 分支，等待 GitHub Pages 完成部署。之后访问 `https://iledehainan.github.io/hainan-history/admin.html`，用上一步创建的管理员账号登录。

任何人都能读取公开历史条目；只有在 `history_admins` 表中登记的用户能新增、编辑或删除资料。用户注册应保持关闭。不要将管理员密码或 `service_role` key 提交到仓库。

## 添加和批量导入资料

后台支持单条新增、编辑、删除以及 CSV 批量导入。CSV 必须为 UTF-8，列名如下：

```text
year,period,type,date,title,place,summary,detail,source,source_url
```

- `year` 是时间排序用的公元整数，公元前用负数，例如公元前110年填 `-110`。年代不确定时用代表性年份，并在详情说明范围和不确定性。
- `period` 必须为 `先秦至汉`、`魏晋至宋元`、`明清时期`、`近现代` 或 `当代`。
- `type` 必须为 `person`、`event`、`trade`、`place` 或 `artifact`，分别表示人物、事件、航线与贸易、港口与遗址、文献与器物。
- 每条资料建议填写可核查的 `source`；存在公开来源网页时填写 `source_url`。

项目新建后，数据库内容为空；现有网页显示 27 条内置资料（含历史建筑、古迹与村落条目）。可在管理员后台逐条添加，或使用批量导入功能。管理员后台提供 `history-architecture-import.csv`，可将这批10条资料加入云端；请只导入一次，并在导入前核对资料来源、年代及重复项。
