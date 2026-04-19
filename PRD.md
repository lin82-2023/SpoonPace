# Product Requirements Document (PRD)
# PacingPal - 长新冠/ME-CFS 能量管理与症状追踪应用

---

## 产品信息

**App Name:** PacingPal (英文名) / **缓行** (中文名)

**Alternative Names:**
- EnergyPulse / 能量脉搏
- PaceGuard / 守步
- SpoonPlan / 勺记

**Tagline:** Manage your energy, reclaim your life

**中文口号：** 管理能量，慢慢生活

**Target Market:**
- Primary: North America & Europe - Long COVID and ME/CFS patients
- Secondary: Hong Kong & Chinese-speaking Southeast Asia

---

## 问题定义

### 用户痛点
1. **Existing tracking tools don't understand pacing** - Generic health apps don't have the energy management concept
2. **Outdated UI** - Most specialized apps are no longer updated, poor user experience
3. **No intelligent analytics** - Only logging, no insights or recommendations
4. **Patients need active energy management** - To avoid crash after overexertion

### 核心问题
> Long COVID and ME/CFS patients need energy pacing to manage symptoms, but there isn't a modern, AI-enabled app specifically for this purpose.

---

## 目标

### 产品目标
- Become the most recommended dedicated energy management app in the Long COVID/ME-CFS community
- Help patients better understand and manage their energy patterns

---

## 用户角色

### Primary User: Sarah, 38, 长新冠患者 2年
- **症状：** 活动后疲劳，需要严格控制每日能量支出
- **痛点：** 之前用 Excel 记录，不方便，无法预测什么时候会崩溃
- **需求：** 快速记录，看到能量使用趋势，得到活动建议
- **愿意付费：** 是，$5/month 完全可接受

### Secondary User: David, 29, ME-CFS 患者 5年
- **症状：** 严重疲劳，需要精确规划每一天
- **痛点：** 现有 app 过时，同步不好用
- **需求：** 跨设备同步，详细的数据分析

### Tertiary User: Caregiver / 家属
- 需要帮患者记录和监控症状
- 需求：简单，清晰，不复杂

---

## 功能优先级规划

### MoSCoW 优先级

---

## MUST HAVE (MVP 必须有) - 第 1 阶段

### 1. 用户认证与同步
- [ ] 邮箱/Apple 登录 (Sign in with Apple 必须，隐私友好)
- [ ] iCloud 同步 (iOS 原生，用户信任)
- [ ] 本地数据存储优先，尊重隐私

### 2. 能量水桶模型 (勺子理论) 核心
- [ ] 每日能量预算设置 (用户设定今日可用能量"勺子"数)
- [ ] 活动登记 - 选择活动类型，消耗对应能量
- [ ] 实时能量剩余显示 (可视化进度条)
- [ ] 能量使用历史查看

### 3. 症状追踪
- [ ] 预设常见症状（疲劳、疼痛、头痛、脑雾等）
- [ ] 0-10 分 severity 评分
- [ ] 快速记录，10秒完成

### 4. 简单日历视图
- [ ] 按日期查看历史记录
- [ ] 一眼看出哪天超支了

### 5. AI 基础功能
- [ ] AI 每周总结 - 根据一周数据，分析能量模式
- [ ] 自然语言输入 - 用户输入文字描述，AI 自动提取活动和症状

### 6. Subscription
- [ ] 7-day free trial
- [ ] Subscription model to unlock full features

**✓ After MVP completion, the product can already solve the core problem**

---

## SHOULD HAVE (第 2 阶段 - MVP 发布后 2-4周)

- [ ] 活动模板/自定义活动 - 用户自定义活动和默认能量消耗
- [ ] 触发因素分析 - AI 帮你找出哪些活动更容易导致症状加重
- [ ] 趋势图表 - 症状/能量变化图表
- [ ] 导出数据 - CSV/PDF 导出给医生看

---

## COULD HAVE (第 3 阶段 - 验证 PMF 后)

- [ ] AI 智能日程规划 - 根据你的能量预算，帮你安排一周活动
- [ ] 今日活动建议 - 根据你今天剩余能量，推荐适合/不适合的活动
- [ ] 日记功能 - 记录更多细节
- [ ] 睡眠整合 - 读取 Apple Health 睡眠数据，分析睡眠对能量影响
- [ ] 小组件 - 首页快速查看今日剩余能量

---

## WON'T HAVE (暂不做，至少 6 个月内不考虑)

- [ ] 社交功能/社区 - 患者不需要在 app 里社交，他们已有 Reddit/Facebook
- [ ] 医患沟通平台 - 太复杂，合规问题多
- [ ] Android 版本 - 先做 iOS，验证成功再扩展
- [ ] 用药追踪 - 聚焦能量 pacing，保持专注

---

## MVP 开发路线图

### Phase 1: 项目搭建 (1-2周)

| 任务 | 工期 | 依赖 |
|------|------|------|
| Xcode 项目初始化，SwiftUI 架构 | 2d | - |
| 配置 SwiftData 本地存储 | 1d | 项目初始化 |
| 配置 Subscription 订阅功能 (StoreKit) | 2d | - |
| Apple 登录集成 | 1d | - |
| iCloud 同步配置 | 2d | SwiftData |
| **合计** | **8 天** | |

---

### Phase 2: 核心功能开发 (2-3周)

| 任务 | 工期 |
|------|------|
| 首页 - 今日能量水桶视图 | 2d |
| 活动记录功能 | 2d |
| 症状记录功能 | 2d |
| 日历/历史页面 | 2d |
| 设置页面 | 1d |
| **合计** | **9 天** |

---

### Phase 3: AI 功能集成 (1周)

| 任务 | 工期 |
|------|------|
| 自然语言输入处理 API 集成 | 2d |
| 每周总结分析功能 | 2d |
| 错误处理，配额控制 | 1d |
| **合计** | **5 天** |

---

### Phase 4: UI/UX 打磨 + 测试 + 提交 (1-2周)

| 任务 | 工期 |
|------|------|
| 设计系统统一，色彩，字体 | 2d |
| 用户测试 (找患者朋友测试) | 2d |
| Bug 修复 | 2d |
| App Store 元数据准备 | 1d |
| 提交审核 | 1d |
| **合计** | **8 天** |

---

## 总 MVP 工期预估: **4-6周**

如果是你一个人全职开发，**大约 1个月**可以推出 MVP。
如果是业余时间做，大约 2-3个月。

---

## 详细功能说明

### 核心概念：能量水桶 / 勺子理论

患者的每日能量就像一桶水/一把勺子。每个活动消耗一定能量。超过了就会导致症状加重（崩溃）。
Pacing 的核心就是保持在能量预算以内，避免崩溃。

**用户流程：**
1. 用户早上设定今天有多少能量（比如 5 勺子）
2. 用户每次做活动，记录下来，扣掉相应能量
3. app 实时显示还剩多少
4. 晚上看今天是否超支
5. AI 每周分析，帮用户了解自己的模式

### 预设活动和能量消耗建议

| 活动 | 默认消耗 (勺子) |
|------|----------------|
| 洗澡 | 1-2 |
| 做饭 | 2-3 |
| 散步 10分钟 | 1 |
| 工作 1小时 | 3-4 |
| 购物 | 3 |
| 社交聚会 | 4-5 |

用户可以自由修改这些默认值。

### 预设症状

- 疲劳 (Fatigue)
- 疼痛 (Pain)
- 头痛/偏头痛 (Headache/Migraine)
- 脑雾 (Brain fog)
- 呼吸困难 (Shortness of breath)
- 睡眠问题 (Sleep issues)
- 恶心 (Nausea)
- 心跳过速 (Heart palpitations)

用户可自定义添加。

### AI 功能详情

#### 1. 自然语言输入
用户输入：
> "今天早上散步了20分钟，现在有点头痛，强度是 6/10"

AI 自动提取：
- 活动：散步 20分钟 → 消耗 2 勺子
- 症状：头痛 → 6/10

**技术实现：** 通过 Claude/GPT API 结构化提取，prompt 工程即可。

#### 2. 每周 AI 总结
AI 分析一周数据，输出：
> "这周你有 3天能量超支，通常在散步超过 30分钟后疲劳度增加 30%。建议你把散步分成两次15分钟，中间休息。"

---

## 架构设计 (生产级)

### 技术栈 (iOS 原生)
- **UI:** SwiftUI (iOS 17+)
- **数据存储:** SwiftData + iCloud
- **订阅:** StoreKit 2
- **认证:** Sign in with Apple
- **AI:** Anthropic Claude 3 Haiku / OpenAI GPT-4-mini （API 调用，成本极低）
- **隐私:** 所有敏感数据本地存储，只在用户允许下同步

### 隐私合规非常重要
- 不收集用户健康数据给广告商
- 透明隐私政策
- 可选端侧处理（如果后来做大了，可以集成 on-device AI）

## App Store ASO 优化建议

### 英文 (美国)
- **Title (30 chars):** `PacingPal: Energy Manager`
- **Subtitle (30 chars):** `For Long COVID & ME/CFS`
- **Keywords (100 chars - 无空格逗号分隔):**
  ```
  longcovid,mecfs,chronicfatigue,pacing,energy,management,symptom,tracker,spoontheory,postviral,fatigue,health,wellness
  ```

### 繁体中文 (香港/台湾)
- **Title:** `缓行 - 能量管理`
- **Subtitle:** `长新冠慢性疲劳追踪`
- **Keywords:**
  ```
  长新冠,慢性疲劳,能量管理,症状追踪,me-cfs,步调,缓行,健康
  ```

---

## 风险与应对

| 风险 | 应对 |
|------|------|
| AI API 成本过高 | 用 Claude 3 Haiku / GPT-4-mini，每个请求 $0.000X，2000用户每月几十美元 |
| Apple 审核不通过 | 声明这不是医疗设备，是自我管理工具，明确说不取代医生 |
| 用户获取难 | 社区本来就在找好产品，做好了会自发传播 |
| 竞争 | 现有产品体验太差，用户会换 |

---

## Next Steps

1. ✅ PRD 完成
2. 开始 Phase 1 - 项目搭建
3. 核心开发
4. beta 测试（找几十个患者测试）
5. 发布到 App Store
6. 社区推广
7. 根据反馈迭代

---

**文档版本:** 1.0
**最后更新:** 2026-04-18
