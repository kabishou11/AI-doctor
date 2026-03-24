import { defineStore } from 'pinia'

const KNOWLEDGE_KEY = 'kb_docs_v1'
const KNOWLEDGE_CHUNKS_KEY = 'kb_chunks_v1'
const EMBEDDING_CONFIG_KEY = 'kb_embedding_config_v1'
const RETRIEVAL_CONFIG_KEY = 'kb_retrieval_config_v1'
const COLLECTIONS_KEY = 'kb_collections_v1'
const PRESET_INITIALIZED_KEY = 'kb_preset_initialized_v2'

// Preset knowledge base data
const PRESET_COLLECTIONS = [
  { id: 'col-first-aid', name: '急救知识', color: '#f5222d', description: '常见急症处理与急救技能', createdAt: new Date().toISOString() },
  { id: 'col-cardiovascular', name: '心血管指南', color: '#eb2f96', description: '心血管疾病诊疗指南', createdAt: new Date().toISOString() },
  { id: 'col-drug', name: '药物相互作用', color: '#722ed1', description: '常用药物配伍与禁忌', createdAt: new Date().toISOString() },
  { id: 'col-respiratory', name: '呼吸系统', color: '#13c2c2', description: '呼吸系统疾病诊治', createdAt: new Date().toISOString() },
  { id: 'col-diabetes', name: '糖尿病管理', color: '#fa8c16', description: '糖尿病患者管理与教育', createdAt: new Date().toISOString() }
]

const PRESET_DOCS = [
  // 急救知识集合
  {
    id: 'doc-first-aid-1',
    collectionId: 'col-first-aid',
    title: '心肺复苏术（CPR）操作指南',
    tags: ['急救', 'CPR', '心肺复苏', '心脏骤停'],
    excerpt: '心肺复苏术是抢救心脏骤停患者的关键技能，包括胸外按压和人工呼吸。',
    content: `心肺复苏术（CPR）操作指南

一、适用场景
当发现患者突然意识丧失、没有呼吸或呼吸异常（如喘息）、无脉搏时，应立即启动心肺复苏。

二、操作步骤

1. 确保现场安全
确认现场对救护者和患者均安全。

2. 检查意识与呼吸
轻拍患者肩部并大声呼叫，检查是否有呼吸（看、听、感觉），时间不超过10秒。

3. 呼叫急救
指定在场人员拨打120，取AED（自动体外除颤仪）。

4. 胸外按压
- 位置：两乳头连线中点（胸骨下半部）
- 深度：成人5-6厘米
- 频率：100-120次/分钟
- 手法：双手交叉，用掌根按压
- 每次按压后让胸廓完全回弹

5. 人工呼吸（可选）
如会做且愿意进行，每30次按压后给2次人工呼吸，每次吹气约1秒，可见胸廓微微起伏。

6. 使用AED
取得AED后立即开机，按语音提示操作，贴电极片、进行分析、放电时确保无人接触患者。

三、注意事项
- 持续按压直到急救人员到达或患者恢复意识
- 如不会人工呼吸，可只进行单纯胸外按压
- AED分析时和放电时必须确保无人接触患者`,
    createdAt: new Date().toISOString()
  },
  {
    id: 'doc-first-aid-2',
    collectionId: 'col-first-aid',
    title: '海姆立克急救法（气道异物梗阻）',
    tags: ['急救', '气道异物', '窒息', '海姆立克'],
    excerpt: '海姆立克急救法是处理气道异物梗阻的标准方法，适用于成人和儿童。',
    content: `海姆立克急救法（气道异物梗阻）

一、适用场景
患者进食或异物入口后突然出现：
- 不能说话、不能咳嗽、几乎无法呼吸
- 用手捏住喉咙（窒息征象）
- 面部或嘴唇发青

二、成人及儿童操作

1. 背部叩击
先拍背：用力在两肩胛骨之间拍打5次。

2. 腹部冲击（海姆立克手法）
拍背无效时，站于患者身后，双手环抱患者腰部。
- 一手握拳，拇指侧抵住患者腹部（脐上约2横指处）
- 另一手握住拳头
- 快速向内、向上冲击5次
- 每次冲击应产生足够的气流将异物冲出

3. 反复交替
反复进行背部叩击和腹部冲击，直到异物排出或患者失去意识。

三、特殊人群
- 孕妇/肥胖者：冲击位置改为胸骨下半部
- 婴儿：采用5次拍背+5次压胸法，面部朝下骑跨在手臂上

四、注意事项
- 不要在异物可见时用手去掏
- 冲击时注意力度，避免损伤肋骨或内脏`,
    createdAt: new Date().toISOString()
  },
  {
    id: 'doc-first-aid-3',
    collectionId: 'col-first-aid',
    title: '急性心肌梗死（AMI）院前识别与处理',
    tags: ['急救', '心肌梗死', 'AMI', '胸痛'],
    excerpt: '急性心肌梗死是威胁生命的急症，院前正确识别和处理可显著改善预后。',
    content: `急性心肌梗死（AMI）院前识别与处理

一、典型症状
- 压榨样胸痛，持续超过20分钟
- 疼痛可放射至左臂、颈部、下颌、背部
- 伴大汗、恶心、呕吐
- 呼吸困难、乏力

二、非典型表现（老年人、糖尿病、女性常见）
- 仅表现为上腹部不适、呼吸困难
- 乏力、晕厥为主要表现
- 无明显胸痛（无痛性心肌梗死）

三、院前处理要点

1. 立即让患者停止活动，绝对卧床
2. 拨打120，怀疑心梗时强调需要胸痛中心
3. 测量生命体征
4. 吸氧（血氧<94%时）
5. 嚼服阿司匹林300mg（无过敏史）
6. 硝酸甘油：血压>90/60mmHg时，可舌下含服1片，5分钟可重复，最多3片
7. 监测心律，准备除颤

四、禁止事项
- 不要让患者自行前往医院
- 血压<90/60mmHg时禁用硝酸甘油
- 疑似心梗时慎重使用PPI（质子泵抑制剂）

五、黄金时间
- 发病到球囊扩张（D2B）时间：<90分钟
- 发病到溶栓（FMC-N）时间：<30分钟`,
    createdAt: new Date().toISOString()
  },
  // 心血管指南集合
  {
    id: 'doc-cv-1',
    collectionId: 'col-cardiovascular',
    title: '2024年中国高血压防治指南要点',
    tags: ['高血压', '指南', '心血管', '诊疗'],
    excerpt: '2024年中国高血压防治指南更新了血压标准、治疗目标和药物推荐。',
    content: `2024年中国高血压防治指南要点

一、血压分级标准（mmHg）

| 分类 | 收缩压 | 舒张压 |
|------|--------|--------|
| 正常 | <120 和 | <80 |
| 正常高值 | 120-129 和 | <80 |
| 高血压 | ≥140 和/或 | ≥90 |

二、治疗目标
- 一般患者：<140/90mmHg
- 能耐受者：<130/80mmHg
- 老年患者：<150/90mmHg，可逐步降至<140/90mmHg

三、血压测量方法
1. 诊室血压：连续测量2次，取平均值
2. 家庭血压监测（HBPM）：早晚餐前各测2次，取平均值
3. 动态血压（ABPM）：24小时平均<130/80mmHg

四、初始药物治疗

一线药物（五类）：
1. ACEI/ARB：培哚普利、缬沙坦等
2. CCB：氨氯地平、硝苯地平等
3. 噻嗪类利尿剂：氢氯噻嗪、吲达帕胺
4. β受体阻滞剂：美托洛尔（适用于冠心病、心衰）
5. ARNI：沙库巴曲缬沙坦

五、联合治疗方案
- 2级高血压（≥160/100mmHg）直接启动联合治疗
- 推荐方案：CCB+ACEI/ARB、CCB+噻嗪类利尿剂
- 不推荐ACEI+ARB联合`,
    createdAt: new Date().toISOString()
  },
  {
    id: 'doc-cv-2',
    collectionId: 'col-cardiovascular',
    title: '急性心力衰竭处理流程',
    tags: ['心衰', '急性心衰', '抢救', '心血管'],
    excerpt: '急性心力衰竭是危及生命的急症，需要快速识别和规范化治疗。',
    content: `急性心力衰竭处理流程

一、临床分型
- 干暖型：轻度心衰，可口服药物调整
- 干冷型：心输出量低，需血管活性药物
- 湿暖型：容量超负荷，利尿为主
- 湿冷型：最严重，心源性休克

二、急诊处理

1. 体位
- 端坐位或半卧位，双腿下垂
- 急性肺水肿：坐位，双下肢浸入温水（扩血管）

2. 氧疗与通气
- 鼻导管：SpO2<90%时，5-10L/分
- 面罩：SpO2<85%或呼吸衰竭时
- 无创通气（CPAP/BiPAP）：意识清楚、呼吸窘迫者
- 气管插管：上述无效或昏迷者

3. 药物治疗

利尿剂（首选）：
- 呋塞米：iv 20-40mg，15-30分钟起效
- 效果不佳：加倍或重复使用，总量可达200-400mg
- 监测：尿量、电解质、肾功能

血管扩张剂：
- 硝酸甘油：0.5-1mg 舌下，或iv 10-200ug/min
- 硝普钠：iv 0.3-5ug/kg/min（避光）
- 适应症：血压>90/60mmHg，无流出道梗阻

正性肌力药：
- 多巴酚丁胺：2-20ug/kg/min
- 米力农：0.375-0.75ug/kg/min
- 适用于：低灌注、对扩血管和利尿反应差者

三、监测指标
- 生命体征持续监测
- 尿量>0.5ml/kg/h
- BNP/NT-proBNP动态监测
- 乳酸、GDT、血气分析`,
    createdAt: new Date().toISOString()
  },
  {
    id: 'doc-cv-3',
    collectionId: 'col-cardiovascular',
    title: '心房颤动抗凝治疗策略',
    tags: ['房颤', '抗凝', 'CHA2DS2-VASc', 'NOAC'],
    excerpt: '房颤患者抗凝治疗是预防脑卒中的核心措施，需根据评分选择方案。',
    content: `心房颤动抗凝治疗策略

一、卒中风险评估（CHA2DS2-VASc评分）

| 因素 | 积分 |
|------|------|
| 充血性心衰 | 1 |
| 高血压 | 1 |
| 年龄≥75岁 | 2 |
| 糖尿病 | 1 |
| 卒中/TIA/血栓史 | 2 |
| 血管疾病 | 1 |
| 年龄65-74岁 | 1 |
| 女性 | 1 |

二、抗凝指征
- CHA2DS2-VASc≥2分（男性）或≥3分（女性）：推荐抗凝
- CHA2DS2-VASc=1分（男性）或=2分（女性）：考虑抗凝
- CHA2DS2-VASc=0分：无需抗凝

三、抗凝药物选择

1. NOAC（首选）
- 达比加群：150mg Bid（110mg Bid老年人/高出血风险）
- 利伐沙班：20mg Qd（15mg Qd CrCl 30-49）
- 阿哌沙班：5mg Bid（2.5mg Bid符合以下2条）
- 艾多沙班：60mg Qd（30mg CrCl 15-50）

2. 华法林
- 目标INR：2.0-3.0
- 用于：机械瓣膜、严重肾功能不全（CrCl<30）

四、出血风险评估（HAS-BLED）
- ≥3分：高出血风险，需密切监测
- 纠正可逆因素：BP、饮酒、药物（NSAIDs）

五、特殊人群
- 老年人：NOAC更安全，调整剂量
- 肾功能不全：达比加群禁用CrCl<30，利伐沙班禁用<15
- 冠脉介入后：三联抗栓（NOAC+氯吡格雷+阿司匹林）时间尽量缩短`,
    createdAt: new Date().toISOString()
  },
  // 药物相互作用集合
  {
    id: 'doc-drug-1',
    collectionId: 'col-drug',
    title: '常见药物配伍禁忌速查表',
    tags: ['药物', '配伍禁忌', '药学', '用药安全'],
    excerpt: '汇总临床常用药物的配伍禁忌，包括注射剂配伍和口服药物相互作用。',
    content: `常见药物配伍禁忌速查表

一、注射剂配伍禁忌

1. 胰岛素配伍
- 禁忌与促皮质素（ACTH）、氢化可的松混合
- 禁忌与氨茶碱、维生素C、碳酸氢钠同瓶滴注
- 乳酸钠林格液中胰岛素需单独通路

2. 抗菌药物配伍
- 青霉素G：禁止与氨基糖苷类同瓶（降效）
- 头孢类：禁止与钙剂、氨基糖苷类同瓶
- 阿昔洛韦：禁止与膦甲酸钠、干扰素同瓶

3. 多巴胺/多巴酚丁胺
- 禁止与碱性药物（碳酸氢钠）同瓶
- 禁止与呋塞米同瓶（产生沉淀）

二、口服药物相互作用

1. 华法林相关
- 增强抗凝：阿司匹林、NSAIDs、氟康唑、大环内酯
- 减弱抗凝：维生素K、苯巴比妥、利福平
- 原则：华法林与任何影响血小板功能药物联用需谨慎

2. 他汀类药物相互作用
- 辛伐他汀：禁忌与伊曲康唑、酮康唑、克拉霉素联用
- 阿托伐他汀：与克拉霉素需减量
- 原则：肝脏代谢（CYP3A4）他汀避免与强抑制剂联用

3. ACEI/ARB类
- 禁忌与保钾利尿剂+钾补充剂联用（高钾血症风险）
- 与NSAIDs联用：降低降压效果，增加肾损风险

三、食物与药物相互作用
- 葡萄柚汁：升高他汀类（除普伐他汀）、氨氯地平血药浓度
- 维生素K：减弱华法林作用
- 酒精：增强镇静药物作用，损伤肝脏代谢功能`,
    createdAt: new Date().toISOString()
  },
  {
    id: 'doc-drug-2',
    collectionId: 'col-drug',
    title: '抗菌药物使用原则与分级管理',
    tags: ['抗菌药物', '抗生素', '分级管理', '耐药'],
    excerpt: '抗菌药物临床应用的分级管理制度与非限制使用、限制使用、特殊使用级药物目录。',
    content: `抗菌药物临床应用与管理

一、分级管理制度

1. 非限制使用级
- 一线用药，安全性证据充分
- 优先选择，价格相对低廉
- 代表：青霉素、阿莫西林、头孢氨苄、阿奇霉素、左氧氟沙星

2. 限制使用级
- 需要根据药敏或临床具体情况选用
- 需要副主任医师以上审批
- 代表：哌拉西林、头孢呋辛、头孢克肟、莫西沙星

3. 特殊使用级
- 新一代抗菌药物或需要保护
- 需要主任医师审批，会诊制度
- 代表：碳青霉烯类、万古霉素、替考拉宁、利福平

二、经验性治疗原则

1. 社区获得性感染（CAP）
- 轻症：阿莫西林、多西环素、大环内酯
- 有合并症：β内酰胺+大环内酯/氟喹诺酮
- 需要住院：β内酰胺+大环内酯

2. 医院获得性感染（HAP）
- 轻症：二三头孢、氟喹诺酮
- 重症：抗假单胞菌β内酰胺+氟喹诺酮/氨基糖苷

三、联合用药指征
- 病因不明的严重感染
- 单一药物不能控制的混合感染
- 需长疗程治疗但易产生耐药
- 减少单一药物剂量以降低毒性

四、特殊人群用药
- 老年人：减量使用肾毒性药物，警惕二重感染
- 儿童：避免氟喹诺酮、四环素（<8岁）
- 孕妇：B类药物优先，禁用喹诺酮、氨基糖苷`,
    createdAt: new Date().toISOString()
  },
  {
    id: 'doc-drug-3',
    collectionId: 'col-drug',
    title: '质子泵抑制剂（PPIs）临床应用与注意事项',
    tags: ['PPIs', '质子泵抑制剂', '胃药', '用药安全'],
    excerpt: 'PPIs是临床最常用的抑酸药物，需要注意适应症、用法用量和长期使用风险。',
    content: `质子泵抑制剂（PPIs）临床应用指南

一、适应症

1. 首选适应症
- 消化性溃疡（胃溃疡、十二指肠溃疡）
- 胃食管反流病（GERD）
- 幽门螺杆菌根除治疗
- 非甾体抗炎药（NSAIDs）相关溃疡预防

2. 二级预防
- 长期使用糖皮质激素+ NSAIDs
- 抗血小板药物联合使用
- 有消化道出血病史的高危患者

二、常用PPIs及用法

| 药物 | 常规剂量 | 特殊用法 |
|------|----------|----------|
| 奥美拉唑 | 20mg QD | 鼻胃管给药 |
| 兰索拉唑 | 30mg QD | - |
| 泮托拉唑 | 40mg QD | 肝脏代谢，肝损首选 |
| 雷贝拉唑 | 20mg QD | 起效快，抑酸强 |
| 艾司奥美拉唑 | 40mg QD | 难治性GERD首选 |

三、服药时间
- 通常：早餐前30-60分钟
- Bid用法：早餐前+晚餐前
- 吞服，不可嚼碎

四、长期使用风险

1. 骨质疏松与骨折
- 机制：影响钙吸收
- 措施：长期使用（>1年）监测骨密度

2. 维生素B12缺乏
- 老年人，长期使用（>3年）风险增加
- 监测血清B12水平

3. 低镁血症
- 罕见但严重，可致心律失常
- 用药前和用药中监测血镁

4. 艰难梭菌感染
- 胃酸屏障被抑制
- 老年人、高危患者注意

5. 萎缩性胃炎
- 长期高强度抑酸可能影响
- 定期胃镜复查

五、药物相互作用
- 氯吡格雷：奥美拉唑、艾司奥美拉唑影响抗血小板作用
- 华法林：所有PPIs均可能增强抗凝作用
- 甲氨蝶呤：PPIs降低其清除，增加毒性`,
    createdAt: new Date().toISOString()
  },
  // 呼吸系统集合
  {
    id: 'doc-resp-1',
    collectionId: 'col-respiratory',
    title: '社区获得性肺炎（CAP）诊治指南',
    tags: ['肺炎', 'CAP', '抗菌药物', '呼吸系统'],
    excerpt: '社区获得性肺炎的诊断标准、病情评估和治疗方案选择。',
    content: `社区获得性肺炎（CAP）诊治指南

一、诊断标准
符合以下1-4项中任意1项+第5项+除外肺结核/肿瘤等：
1. 新近出现的咳嗽、咳痰或原有呼吸道症状加重
2. 发热
3. 肺实变体征或闻及湿啰音
4. WBC>10×10^9/L或<4×10^9/L
5. 胸部X线或CT显示新出现浸润影

二、病情严重程度评估（CURB-65）

| 指标 | 评分 |
|------|------|
| Confusion（意识障碍） | 1 |
| Urea>7mmol/L | 1 |
| Respiratory≥30次/分 | 1 |
| Blood pressure<90/60mmHg | 1 |
| Age≥65岁 | 1 |

三、治疗决策
- CURB-65=0-1：门诊治疗
- CURB-65=2：住院治疗
- CURB-65≥3：ICU治疗

四、经验性抗感染方案

1. 门诊患者（无基础疾病）
- 阿莫西林、多西环素
- 或阿奇霉素（排除支原体高发区）

2. 门诊患者（有基础疾病/近期抗生素史）
- β内酰胺类+大环内酯类
- 或呼吸喹诺酮单药（莫西沙星、左氧氟沙星）

3. 住院患者（非ICU）
- β内酰胺类（头孢曲松/头孢噻肟/氨苄西林）+大环内酯类
- 或呼吸喹诺酮单药

4. ICU患者
- β内酰胺（头孢曲松/头孢噻肟/哌拉西林他唑巴坦）+大环内酯/喹诺酮
- 铜绿假单胞菌风险时：抗假单胞β内酰胺+喹诺酮/氨基糖苷

五、疗程
- 一般：热退2-3天后改口服，总疗程5-7天
- 复杂或免疫低下：延长至10-14天
- 肺炎支原体/衣原体：10-14天
- 金葡菌、铜绿：21天或更长`,
    createdAt: new Date().toISOString()
  },
  {
    id: 'doc-resp-2',
    collectionId: 'col-respiratory',
    title: '支气管哮喘（Asthma）阶梯治疗方案',
    tags: ['哮喘', 'COPD', '吸入制剂', '呼吸系统'],
    excerpt: '支气管哮喘的诊断、分期与基于GINA指南的阶梯治疗方案。',
    content: `支气管哮喘阶梯治疗方案

一、哮喘诊断
1. 症状：反复发作喘息、气促、胸闷、咳嗽
2. 体征：呼气相为主的弥漫性哮鸣音
3. 辅助：支气管舒张试验阳性（FEV1增加≥12%且≥200ml）
4. PEF日间变异率>10%

二、哮喘分期
1. 急性发作期
2. 慢性持续期
3. 临床缓解期

三、阶梯治疗方案（GINA 2024）

Step 1（间歇哮喘）：
- 按需吸入SABA（沙丁胺醇）
- 低剂量ICS-福莫特罗（按需）

Step 2（轻度持续）：
- 低剂量ICS（吸入糖皮质激素）每日
- 加按需SABA

Step 3（中等持续）：
- 低剂量ICS+LABA（长效β2激动剂）
- 或中等剂量ICS

Step 4（中-重度持续）：
- 中等剂量ICS+LABA
- 可加LAMA（噻托溴铵）

Step 5（重度持续）：
- 高剂量ICS+LABA
- 加用抗IL-5/抗IgE生物制剂
- 考虑支气管热成形术

四、常用吸入制剂

1. ICS（吸入糖皮质激素）
- 布地奈德、丙酸氟替卡松、倍氯米松
- 常见不良反应：口腔念珠菌、声音嘶哑
- 预防：吸入后漱口

2. LABA（长效β2激动剂）
- 福莫特罗、沙美特罗
- 注意：不单独使用，必须与ICS联用

3. SABA（短效β2激动剂）
- 沙丁胺醇、特布他林
- 急性发作首选

4. LAMA（长效M受体拮抗剂）
- 噻托溴铵
- 联合治疗可选

五、急性发作处理
1. 吸入SABA：沙丁胺醇 2-4喷，15-20分钟可重复
2. 氧疗：SpO2维持在93-95%
3. 口服泼尼松40-50mg/d，5-7天
4. 必要时静脉：甲泼尼龙、氨茶碱
5. 密切监测呼吸、SpO2`,
    createdAt: new Date().toISOString()
  },
  {
    id: 'doc-resp-3',
    collectionId: 'col-respiratory',
    title: '慢性阻塞性肺疾病（COPD）评估与管理',
    tags: ['COPD', '慢阻肺', '肺功能', '呼吸系统'],
    excerpt: 'COPD的GOLD分级、评估工具（mMRC/CAT）和稳定期管理方案。',
    content: `慢性阻塞性肺疾病（COPD）评估与管理

一、诊断标准
- 症状：呼吸困难、慢性咳嗽、咳痰
- 危险因素：吸烟、职业暴露、生物燃料等
- 肺功能：吸入支气管扩张剂后FEV1/FVC<70%

二、肺功能分级（GOLD）

| 分级 | FEV1占预计值 |
|------|--------------|
| GOLD 1 轻度 | ≥80% |
| GOLD 2 中度 | 50-79% |
| GOLD 3 重度 | 30-49% |
| GOLD 4 极重度 | <30% |

三、症状评估

1. mMRC呼吸困难分级
- 0级：仅在剧烈活动时呼吸困难
- 1级：快走或爬缓坡时气短
- 2级：因呼吸困难比同龄人步行慢或停下
- 3级：平地上行走100米需停下
- 4级：呼吸困难不能离家或穿脱衣服时气短

2. CAT评分（COPD评估测试）
- 8项问卷，总分0-40
- <10分：轻度影响
- 10-20分：中度影响
- 21-30分：严重影响
- >30分：非常严重影响

四、COPD综合评估（ABE分组）

| 分组 | 症状 | 急性加重风险 | 治疗策略 |
|------|------|--------------|----------|
| A组 | mMRC 0-1或CAT<10 | <2次/年 | 支气管扩张剂 |
| B组 | mMRC≥2或CAT≥10 | <2次/年 | LABA或LAMA |
| E组 | 任何症状 | ≥2次/年或1次住院 | LABA+LAMA或ICS+LABA |

五、稳定期药物治疗

1. 首选支气管扩张剂
- LABA：福莫特罗、沙美特罗
- LAMA：噻托溴铵、乌美溴铵
- 推荐：长效制剂，按需使用SABA

2. ICS（吸入糖皮质激素）指征
- FEV1<50%+反复急性加重
- 血嗜酸粒细胞≥300/μL

3. 联合治疗
- LABA+LAMA：FEV1<50%或症状重
- 三联（ICS+LABA+LAMA）：GOLD E组且症状持续

六、急性加重处理
- 抗菌药物：脓痰+呼吸困难加重
- 支气管扩张剂：增加SABA
- 糖皮质激素：泼尼松30-40mg/d，5-7天
- 氧疗：无高碳酸血症风险时，目标SpO2 94-98%`,
    createdAt: new Date().toISOString()
  },
  // 糖尿病管理集合
  {
    id: 'doc-dm-1',
    collectionId: 'col-diabetes',
    title: '2型糖尿病诊断标准与分型',
    tags: ['糖尿病', '诊断', 'HbA1c', '内分泌'],
    excerpt: '糖尿病的诊断标准、鉴别诊断要点及分型原则。',
    content: `2型糖尿病诊断与分型

一、诊断标准（符合以下任一条件）

1. 典型糖尿病症状+随机血糖≥11.1mmol/L
2. 空腹血糖（FPG）≥7.0mmol/L（空腹定义：至少8小时无热量摄入）
3. OGTT 2小时血糖≥11.1mmol/L
4. 糖化血红蛋白（HbA1c）≥6.5%

若无典型症状，需改日复查确认。

二、HbA1c的临床应用
- 反映近2-3月平均血糖水平
- 正常值：4-6%
- 糖尿病诊断标准：≥6.5%
- 控制目标：一般<7%（个体化）

三、糖尿病分型

1. 1型糖尿病
- 胰岛β细胞破坏，胰岛素绝对缺乏
- 特点：发病急、"三多一少"明显、酮症倾向
- 自身抗体阳性（GAD65、IA-2等）
- C肽水平低或测不出

2. 2型糖尿病
- 胰岛素抵抗为主+胰岛功能进行性衰退
- 特点：发病隐匿，常超重/肥胖
- 酮症倾向小，早期无需胰岛素
- 常见于中老年人（但年轻化趋势）

3. 特殊类型糖尿病
- 胰岛β细胞功能遗传缺陷（MODY等）
- 胰岛素作用遗传缺陷
- 胰腺外分泌疾病（胰腺炎、肿瘤等）
- 药物或化学因素（糖皮质激素、甲状腺激素等）
- 感染（先天性风疹等）

4. 妊娠糖尿病（GDM）
- 孕24-28周75g OGTT
- 空腹≥5.1、1h≥10.0、2h≥8.5（任一达标）

四、鉴别诊断要点
- 1型 vs 2型：抗体、C肽、临床表现
- 糖尿病酮症酸中毒（DKA）：血糖多<16.7，高血酮，代谢性酸中毒
- 高渗高血糖综合征（HHS）：血糖>33.3，无明显酮症`,
    createdAt: new Date().toISOString()
  },
  {
    id: 'doc-dm-2',
    collectionId: 'col-diabetes',
    title: '糖尿病药物治疗方案选择',
    tags: ['糖尿病', '降糖药', '胰岛素', '个体化治疗'],
    excerpt: '口服降糖药分类、作用机制和2型糖尿病的药物治疗路径。',
    content: `糖尿病药物治疗方案

一、口服降糖药分类

1. 二甲双胍
- 机制：减少肝糖输出，增加外周利用
- 优点：降HbA1c 1-1.5%，不增加体重，低血糖风险小
- 副作用：胃肠道反应，维生素B12缺乏
- 禁忌：eGFR<30、急性心衰、严重肝病、造影剂前后
- 地位：2型糖尿病一线首选，除非不耐受或禁忌

2. 磺脲类
- 机制：促进胰岛素分泌
- 药物：格列美脲、格列齐特、格列吡嗪
- 降HbA1c 1-1.5%
- 注意：低血糖风险，老年人选用短效

3. 格列奈类
- 机制：餐时促分泌，控制餐后血糖
- 药物：瑞格列奈、那格列奈
- 降HbA1c 0.5-1%
- 适用于：餐后血糖高、餐时不规律

4. α-糖苷酶抑制剂
- 机制：延缓碳水吸收
- 药物：阿卡波糖、伏格列波糖
- 降HbA1c 0.5-0.8%
- 注意：胃肠道反应，与胰岛素联用防低血糖

5. TZDs（噻唑烷二酮类）
- 机制：改善胰岛素抵抗
- 药物：吡格列酮
- 增加骨折风险，心衰禁用

6. DPP-4抑制剂
- 机制：GLP-1降解酶抑制剂
- 药物：西格列汀、利格列汀、沙格列汀
- 降HbA1c 0.5-0.8%，不引起低血糖

7. SGLT-2抑制剂
- 机制：抑制肾脏葡萄糖重吸收
- 药物：恩格列净、达格列净、卡格列净
- 降HbA1c 0.5-1%
- 额外获益：心肾保护、减重
- 注意：泌尿生殖道感染、DKA

二、药物治疗路径

1. 无ASCVD/心衰/CKD
- 首选：二甲双胍
- HbA1c未达标+10%：加第二种药
- 可选：磺脲类、DPP-4i、SGLT-2i、GLP-1RA

2. 有ASCVD/心衰/CKD
- 首选：二甲双胍+SGLT-2i或GLP-1RA
- SGLT-2i有心衰保护，GLP-1RA有心血管获益

三、胰岛素治疗

1. 起始方案
- 基础胰岛素：甘精胰岛素、德谷胰岛素
- 基础-餐食方案：≥1.5种口服药血糖仍高

2. 强化方案
- 基础-餐食：基础+餐前短效
- 预混胰岛素：每日1-3次
- 胰岛素泵：脆性糖尿病

3. 剂量调整
- 起始：0.1-0.2 U/kg/d
- 目标：空腹4.4-7.0 mmol/L
- 调整：根据血糖监测结果`,
    createdAt: new Date().toISOString()
  },
  {
    id: 'doc-dm-3',
    collectionId: 'col-diabetes',
    title: '糖尿病慢性并发症筛查与管理',
    tags: ['糖尿病', '并发症', '糖尿病肾病', '糖尿病视网膜病变'],
    excerpt: '糖尿病主要慢性并发症的筛查频率、诊断标准和随访管理要点。',
    content: `糖尿病慢性并发症筛查与管理

一、糖尿病肾病（DKD）

1. 筛查
- 诊断时即开始，以后每年1次
- 项目：尿白蛋白/肌酐比（UACR）、eGFR
- UACR≥30mg/g提示白蛋白尿
- eGFR下降：<60ml/min/1.73m²

2. 分期（KDIGO）
- G1：eGFR≥90
- G2：eGFR 60-89
- G3a：eGFR 45-59
- G3b：eGFR 30-44
- G4：eGFR 15-29
- G5：eGFR<15或透析

3. 管理
- 血糖控制：HbA1c<7%，老年人可放宽
- 血压控制：<130/80mmHg，首选ACEI/ARB
- 蛋白限制：0.8g/kg/d（G4-5期）
- SGLT-2i+GLP-1RA：肾脏保护

二、糖尿病视网膜病变（DR）

1. 筛查
- 诊断时即开始眼底检查
- 1型：5年内开始，每年1次
- 2型：以后每年1次
- 妊娠：妊娠前/早孕+产后1年

2. 分期
- 无明显视网膜病变
- 非增殖期（NPDR）：轻度、中度、重度
- 增殖期（PDR）：新生血管形成
- 糖尿病黄斑水肿（DME）

3. 治疗
- NPDR：控制血糖、血压
- 增殖期/高危PDR：激光光凝
- DME：抗VEGF治疗（雷珠单抗、阿柏西普）

三、糖尿病神经病变

1. 筛查
- 诊断时开始，以后每年1次
- 10g尼龙丝试验、128Hz音叉
- 四肢疼痛、麻木、感觉异常

2. 治疗
- 血糖控制（预防+进展）
- 疼痛：普瑞巴林、度洛西汀、文拉法辛
- 麻木：甲钴胺、硫辛酸
- 足部护理

四、糖尿病足

1. 筛查
- 每年足部检查，包括视诊、触诊
- 10g尼龙丝、128Hz音叉
- 足背动脉搏动

2. 分级（Wagner）
- 0级：有高危因素
- 1级：浅表溃疡
- 2级：深部溃疡
- 3级：深部感染
- 4级：局部坏疽
- 5级：全足坏疽

3. 管理
- 减压：特制鞋垫、轮椅
- 清创：外科/锐器
- 感染：抗菌药物
- 血供：血管介入
- 多学科协作（MDT）

五、其他并发症
- 心血管疾病：LDL-C<2.6（高危<1.8）
- 脑血管病：抗血小板聚集
- 骨质疏松：DXA筛查，补充钙剂、维生素D`,
    createdAt: new Date().toISOString()
  }
]

// Helper functions for retrieval
function bm25Score(query, text, k1 = 1.5, b = 0.75) {
  const queryTerms = query.toLowerCase().split(/[\s,，。；;、：:]+/).filter(Boolean)
  const textLower = text.toLowerCase()
  const textTerms = textLower.split(/[\s,，。；;、：:]+/).filter(Boolean)

  if (!queryTerms.length || !textTerms.length) return 0

  // Calculate term frequencies
  const termFreq = {}
  textTerms.forEach(term => {
    termFreq[term] = (termFreq[term] || 0) + 1
  })

  // BM25 scoring
  const avgDL = textTerms.length // Simplified: use document length as average
  let score = 0
  const dl = textTerms.length
  const N = 1 // Simplified document count
  const idf = Math.log((N + 0.5) / 0.5) // Simplified IDF

  queryTerms.forEach(qTerm => {
    if (textLower.includes(qTerm)) {
      const tf = termFreq[qTerm] || 0
      const numerator = tf * (k1 + 1)
      const denominator = tf + k1 * (1 - b + b * (dl / avgDL))
      score += idf * (numerator / denominator)
    }
  })

  return score
}

function rrfScore(scores, k = 60) {
  // Reciprocal Rank Fusion for result re-ranking
  const fused = {}
  scores.forEach(({ id, score, rank }) => {
    if (!fused[id]) fused[id] = { id, totalScore: 0, count: 0 }
    fused[id].totalScore += score / (k + rank)
    fused[id].count += 1
  })
  return Object.values(fused)
    .map(item => ({
      id: item.id,
      score: item.totalScore
    }))
    .sort((a, b) => b.score - a.score)
}

function deduplicateResults(results, key = 'docId') {
  const seen = new Set()
  return results.filter(r => {
    if (seen.has(r[key])) return false
    seen.add(r[key])
    return true
  })
}

function rerankResults(results, query, topN = 5) {
  // Simple MMR-like re-ranking based on content relevance
  if (results.length <= topN) return results

  const scored = results.map(r => {
    const qTerms = query.toLowerCase().split(/[\s,，。；;]+/).filter(Boolean)
    const cTerms = (r.content || '').toLowerCase().split(/[\s,，。；;]+/).filter(Boolean)
    let relevance = 0
    qTerms.forEach(q => {
      if (cTerms.some(c => c.includes(q) || q.includes(c))) relevance += 1
    })
    return { ...r, relevanceScore: relevance / Math.max(qTerms.length, 1) }
  })

  return scored
    .sort((a, b) => b.score - b.score + (b.relevanceScore - a.relevanceScore) * 0.1)
    .slice(0, topN)
}

function genId(prefix = 'kb') {
  return `${prefix}-${Date.now()}-${Math.random().toString(16).slice(2, 8)}`
}

function normalizeDoc(doc) {
  if (!doc) return null
  return {
    id: typeof doc.id === 'string' && doc.id ? doc.id : genId(),
    title: typeof doc.title === 'string' ? doc.title : '未命名文档',
    tags: Array.isArray(doc.tags) ? doc.tags.filter(Boolean) : [],
    collectionId: typeof doc.collectionId === 'string' ? doc.collectionId : '',
    content: typeof doc.content === 'string' ? doc.content : '',
    excerpt: typeof doc.excerpt === 'string' ? doc.excerpt : '',
    createdAt: doc.createdAt || new Date().toISOString(),
    updatedAt: doc.updatedAt || new Date().toISOString()
  }
}

function loadDocs() {
  try {
    const raw = localStorage.getItem(KNOWLEDGE_KEY)
    if (!raw) return []
    const parsed = JSON.parse(raw)
    if (!Array.isArray(parsed)) return []
    return parsed.map((d) => normalizeDoc(d)).filter(Boolean)
  } catch (e) {
    return []
  }
}

function saveDocs(docs) {
  localStorage.setItem(KNOWLEDGE_KEY, JSON.stringify(docs || []))
}

export const useKnowledgeStore = defineStore('knowledge', {
  state: () => ({
    docs: loadDocs(),
    chunks: loadChunks(),
    collections: loadCollections(),
    pinnedIds: [],
    embeddingConfig: loadEmbeddingConfig(),
    retrievalConfig: loadRetrievalConfig()
  }),
  getters: {
    docMap(state) {
      return new Map((state.docs || []).map((d) => [d.id, d]))
    },
    byCollection: (state) => {
      const grouped = {}
      for (const doc of state.docs || []) {
        const key = doc.collectionId || 'default'
        if (!grouped[key]) grouped[key] = []
        grouped[key].push(doc)
      }
      return grouped
    }
  },
  actions: {
    addDoc(payload) {
      const doc = normalizeDoc(payload)
      doc.createdAt = doc.createdAt || new Date().toISOString()
      doc.updatedAt = new Date().toISOString()
      this.docs.unshift(doc)
      saveDocs(this.docs)
      return doc.id
    },
    updateDoc(id, patch) {
      const idx = this.docs.findIndex((d) => d.id === id)
      if (idx === -1) return
      const next = normalizeDoc({ ...this.docs[idx], ...patch, id })
      next.createdAt = this.docs[idx].createdAt || next.createdAt
      next.updatedAt = new Date().toISOString()
      this.docs.splice(idx, 1, next)
      saveDocs(this.docs)
    },
    removeDoc(id) {
      this.docs = this.docs.filter((d) => d.id !== id)
      this.pinnedIds = this.pinnedIds.filter((pid) => pid !== id)
      this.chunks = this.chunks.filter((c) => c.docId !== id)
      saveDocs(this.docs)
      saveChunks(this.chunks)
    },
    setPinned(ids) {
      const valid = Array.isArray(ids) ? ids.filter((x) => typeof x === 'string' && x) : []
      this.pinnedIds = valid
    },
    search(query, tags = []) {
      const q = (query || '').toLowerCase().trim()
      const activeTags = Array.isArray(tags) ? tags.filter(Boolean) : []
      return (this.docs || []).filter((doc) => {
        const inTags = activeTags.length ? activeTags.every((t) => doc.tags?.includes(t)) : true
        if (!inTags) return false
        if (!q) return true
        return (
          doc.title?.toLowerCase().includes(q) ||
          doc.content?.toLowerCase().includes(q) ||
          (doc.tags || []).some((t) => t.toLowerCase().includes(q))
        )
      })
    },
    // Collection management
    addCollection(collection) {
      const newCollection = {
        id: collection?.id || genId('col'),
        name: collection?.name || '未命名集合',
        color: collection?.color || '#1890ff',
        description: collection?.description || '',
        createdAt: new Date().toISOString()
      }
      this.collections.push(newCollection)
      saveCollections(this.collections)
      return newCollection.id
    },
    updateCollection(id, patch) {
      const idx = this.collections.findIndex((c) => c.id === id)
      if (idx === -1) return
      this.collections[idx] = { ...this.collections[idx], ...patch }
      saveCollections(this.collections)
    },
    removeCollection(id) {
      // Move docs in this collection to uncategorized
      this.docs.forEach((doc) => {
        if (doc.collectionId === id) {
          doc.collectionId = ''
        }
      })
      saveDocs(this.docs)
      this.collections = this.collections.filter((c) => c.id !== id)
      saveCollections(this.collections)
    },
    getCollectionById(id) {
      return this.collections.find((c) => c.id === id) || null
    },
    importData(json) {
      try {
        const parsed = typeof json === 'string' ? JSON.parse(json) : json
        const incoming = Array.isArray(parsed?.docs) ? parsed.docs : Array.isArray(parsed) ? parsed : []
        const normalized = incoming.map((d) => normalizeDoc(d)).filter(Boolean)
        // 去重: 以 title+content hash 简单去重
        const existing = new Map()
        for (const doc of this.docs) {
          const key = `${doc.title}::${doc.content}`
          existing.set(key, doc)
        }
        const merged = [...this.docs]
        for (const doc of normalized) {
          const key = `${doc.title}::${doc.content}`
          if (existing.has(key)) continue
          merged.push({ ...doc, id: genId() })
        }
        this.docs = merged
        saveDocs(this.docs)
        return { imported: normalized.length, merged: merged.length }
      } catch (e) {
        throw new Error('导入失败：格式错误或内容无效')
      }
    },
    // Initialize preset knowledge base (call once on first load)
    initializePresetKnowledge() {
      const initialized = localStorage.getItem(PRESET_INITIALIZED_KEY)
      if (initialized) return { collections: 0, docs: 0 }

      // Add preset collections
      for (const col of PRESET_COLLECTIONS) {
        this.collections.push(col)
      }
      saveCollections(this.collections)

      // Add preset docs
      const newDocs = []
      for (const docData of PRESET_DOCS) {
        const doc = normalizeDoc({
          ...docData,
          id: genId(docData.collectionId)
        })
        newDocs.push(doc)
      }
      this.docs = [...this.docs, ...newDocs]
      saveDocs(this.docs)

      localStorage.setItem(PRESET_INITIALIZED_KEY, 'true')
      return { collections: PRESET_COLLECTIONS.length, docs: PRESET_DOCS.length }
    },
    exportData() {
      return JSON.stringify({ docs: this.docs }, null, 2)
    },
    setEmbeddingConfig(config) {
      const payload = {
        provider: config?.provider || 'modelscope',
        model: config?.model || 'text-embedding-v3',
        apiKey: config?.apiKey || '',
        baseUrl: config?.baseUrl || '',
        // Chunk strategy
        chunkStrategy: config?.chunkStrategy || 'sentence',
        chunkSize: Number.isFinite(config?.chunkSize) ? Math.max(100, Math.min(2000, Math.floor(config.chunkSize))) : 800,
        chunkOverlap: Number.isFinite(config?.chunkOverlap) ? Math.max(0, Math.min(500, Math.floor(config.chunkOverlap))) : 100,
        // Advanced options
        normalizeEmbedding: config?.normalizeEmbedding !== undefined ? config.normalizeEmbedding : true,
        batchSize: Number.isFinite(config?.batchSize) ? Math.max(1, Math.min(32, Math.floor(config.batchSize))) : 8,
        // Rerank settings
        rerankEnabled: config?.rerankEnabled !== undefined ? config.rerankEnabled : false,
        rerankModel: config?.rerankModel || '',
        rerankTopK: Number.isFinite(config?.rerankTopK) ? Math.max(3, Math.min(20, Math.floor(config.rerankTopK))) : 10,
        rerankProvider: config?.rerankProvider || ''
      }
      this.embeddingConfig = payload
      saveEmbeddingConfig(payload)
    },
    setRetrievalConfig(config) {
      const payload = {
        // Basic retrieval settings
        topK: Number.isFinite(config?.topK) ? Math.max(1, Math.min(20, Math.floor(config.topK))) : 5,
        keywordWeight: Number.isFinite(config?.keywordWeight) ? Math.min(1, Math.max(0, config.keywordWeight)) : 0.5,
        // Hybrid search options
        vectorWeight: Number.isFinite(config?.vectorWeight) ? Math.min(1, Math.max(0, config.vectorWeight)) : 0.5,
        // BM25 settings
        bm25Enabled: config?.bm25Enabled !== undefined ? config.bm25Enabled : true,
        bm25K1: Number.isFinite(config?.bm25K1) ? Math.max(0.5, Math.min(3, config.bm25K1)) : 1.5,
        bm25B: Number.isFinite(config?.bm25B) ? Math.max(0, Math.min(1, config.bm25B)) : 0.75,
        // Rerank settings
        rerankEnabled: config?.rerankEnabled !== undefined ? config.rerankEnabled : false,
        rerankTopN: Number.isFinite(config?.rerankTopN) ? Math.max(1, Math.min(10, Math.floor(config.rerankTopN))) : 3,
        // Diversity settings
        enableDeduplication: config?.enableDeduplication !== undefined ? config.enableDeduplication : true,
        // Strategy
        strategy: config?.strategy || 'hybrid' // 'hybrid', 'vector', 'keyword', 'rrf'
      }
      this.retrievalConfig = payload
      saveRetrievalConfig(payload)
    },
    async ingestDocument({ title, content, tags = [], collectionId = '', autoVectorize = true }) {
      const id = this.addDoc({ title, content, tags, collectionId })
      if (autoVectorize) {
        await this.reembedDoc(id)
      }
      return id
    },
    async reembedDoc(docId) {
      const doc = this.docs.find((d) => d.id === docId)
      if (!doc) throw new Error('文档不存在')

      const chunkStrategy = this.embeddingConfig?.chunkStrategy || 'sentence'
      const chunkSize = this.embeddingConfig?.chunkSize || 800
      const chunkOverlap = this.embeddingConfig?.chunkOverlap || 100

      const chunks = chunkText(doc.content || '', chunkStrategy, chunkSize, chunkOverlap)
      const embeddings = []
      for (const chunk of chunks) {
        const vector = await embedChunk(chunk, this.embeddingConfig)
        embeddings.push({ id: genId('chunk'), docId, text: chunk, embedding: vector, createdAt: new Date().toISOString() })
      }
      this.chunks = this.chunks.filter((c) => c.docId !== docId).concat(embeddings)
      saveChunks(this.chunks)
      return embeddings.length
    },
    async retrieveContext({ queryText, selectedIds = [], topK, keywordWeight }) {
      const ids = Array.isArray(selectedIds) && selectedIds.length ? new Set(selectedIds) : null
      const availableChunks = ids ? this.chunks.filter((c) => ids.has(c.docId)) : this.chunks
      if (!availableChunks.length) return []

      const config = this.retrievalConfig || {}
      const strategy = config.strategy || 'hybrid'

      // Apply topK from param or config (fetch more for reranking)
      const fetchTopK = Number.isFinite(topK) ? topK : config.topK || 5
      const boundedTopK = Math.max(1, Math.min(20, Math.floor(fetchTopK)))

      // Weights
      const vectorWeight = Number.isFinite(config.vectorWeight) ? config.vectorWeight : 0.5
      const keywordW = Number.isFinite(keywordWeight) ? keywordWeight : config.keywordWeight ?? 0.5

      // Get query embedding
      const queryEmbedding = await embedChunk(queryText || '', this.embeddingConfig)
      const useEmbedding = Array.isArray(queryEmbedding) && queryEmbedding.length

      // Calculate scores based on strategy
      let scoredChunks = []

      if (strategy === 'keyword' || strategy === 'hybrid') {
        // BM25 keyword search
        const bm25K1 = config.bm25K1 || 1.5
        const bm25B = config.bm25B || 0.75
        const keywordResults = availableChunks.map((c) => ({
          chunk: c,
          bm25Score: bm25Score(queryText || '', c.text || '', bm25K1, bm25B)
        }))
        // Simple keyword matching as fallback
        const keywordResultsSimple = availableChunks.map((c) => ({
          chunk: c,
          keywordScore: keywordSimilarity(queryText || '', c.text || '')
        }))

        if (strategy === 'keyword') {
          scoredChunks = availableChunks.map((c) => {
            const bm = keywordResults.find((k) => k.chunk.id === c.id)?.bm25Score || 0
            const kw = keywordResultsSimple.find((k) => k.chunk.id === c.id)?.keywordScore || 0
            return { chunk: c, score: Math.max(bm, kw) }
          })
        } else {
          // Hybrid: combine BM25 and vector
          const vectorResults = useEmbedding
            ? availableChunks.map((c) => ({
                chunk: c,
                vectorScore: cosineSimilarity(queryEmbedding, c.embedding)
              }))
            : []

          scoredChunks = availableChunks.map((c) => {
            const bm = keywordResults.find((k) => k.chunk.id === c.id)?.bm25Score || 0
            const kw = keywordResultsSimple.find((k) => k.chunk.id === c.id)?.keywordScore || 0
            const keywordScore = Math.max(bm, kw)
            const vectorScore = useEmbedding
              ? vectorResults.find((v) => v.chunk.id === c.id)?.vectorScore || 0
              : 0
            // Use vectorWeight for the hybrid combination
            const score = (1 - vectorWeight) * keywordScore + vectorWeight * vectorScore
            return { chunk: c, score, keywordScore, vectorScore }
          })
        }
      } else if (strategy === 'vector') {
        // Pure vector search
        scoredChunks = availableChunks.map((c) => ({
          chunk: c,
          score: useEmbedding ? cosineSimilarity(queryEmbedding, c.embedding) : 0
        }))
      }

      // Sort by score
      let sorted = scoredChunks
        .filter((item) => Number.isFinite(item.score))
        .sort((a, b) => b.score - a.score)

      // Deduplicate by docId if enabled
      if (config.enableDeduplication !== false) {
        sorted = deduplicateResults(sorted, 'docId')
      }

      // Reranking if enabled
      if (config.rerankEnabled) {
        const rerankTopN = config.rerankTopN || 3
        const topForRerank = sorted.slice(0, rerankTopN * 2)
        const reranked = rerankResults(topForRerank, queryText || '', boundedTopK)
        sorted = reranked
      }

      // Take top-K
      const finalResults = sorted.slice(0, boundedTopK).map(({ chunk, score }) => {
        const doc = this.docMap.get(chunk.docId)
        return {
          id: chunk.id,
          docId: chunk.docId,
          title: doc?.title || '未命名文档',
          content: chunk.text,
          score
        }
      })

      // Fallback to document excerpts if no chunks
      if (!finalResults.length) {
        const docs = ids ? this.docs.filter((d) => ids.has(d.id)) : this.docs
        return docs.slice(0, boundedTopK).map((d) => ({
          id: d.id,
          docId: d.id,
          title: d.title,
          content: d.excerpt || d.content
        }))
      }
      return finalResults
    }
  }
})

// helpers
function loadChunks() {
  try {
    const raw = localStorage.getItem(KNOWLEDGE_CHUNKS_KEY)
    if (!raw) return []
    const arr = JSON.parse(raw)
    if (Array.isArray(arr)) return arr
    return []
  } catch (e) {
    return []
  }
}

function saveChunks(chunks) {
  localStorage.setItem(KNOWLEDGE_CHUNKS_KEY, JSON.stringify(chunks || []))
}

function loadCollections() {
  try {
    const raw = localStorage.getItem(COLLECTIONS_KEY)
    if (!raw) return []
    const parsed = JSON.parse(raw)
    if (Array.isArray(parsed)) return parsed
    return []
  } catch (e) {
    return []
  }
}

function saveCollections(collections) {
  localStorage.setItem(COLLECTIONS_KEY, JSON.stringify(collections || []))
}

function loadEmbeddingConfig() {
  try {
    const raw = localStorage.getItem(EMBEDDING_CONFIG_KEY)
    if (!raw) {
      return {
        provider: 'modelscope',
        model: 'text-embedding-v3',
        apiKey: '',
        baseUrl: 'https://api-inference.modelscope.cn/v1',
        chunkStrategy: 'sentence',
        chunkSize: 800,
        chunkOverlap: 100,
        normalizeEmbedding: true,
        batchSize: 8,
        rerankEnabled: false,
        rerankModel: '',
        rerankTopK: 10,
        rerankProvider: ''
      }
    }
    const parsed = JSON.parse(raw)
    return {
      provider: parsed?.provider || 'modelscope',
      model: parsed?.model || 'text-embedding-v3',
      apiKey: parsed?.apiKey || '',
      baseUrl: parsed?.baseUrl || '',
      chunkStrategy: parsed?.chunkStrategy || 'sentence',
      chunkSize: Number.isFinite(parsed?.chunkSize) ? parsed.chunkSize : 800,
      chunkOverlap: Number.isFinite(parsed?.chunkOverlap) ? parsed.chunkOverlap : 100,
      normalizeEmbedding: parsed?.normalizeEmbedding !== undefined ? parsed.normalizeEmbedding : true,
      batchSize: Number.isFinite(parsed?.batchSize) ? parsed.batchSize : 8,
      rerankEnabled: parsed?.rerankEnabled !== undefined ? parsed.rerankEnabled : false,
      rerankModel: parsed?.rerankModel || '',
      rerankTopK: Number.isFinite(parsed?.rerankTopK) ? parsed.rerankTopK : 10,
      rerankProvider: parsed?.rerankProvider || ''
    }
  } catch (e) {
    return {
      provider: 'modelscope',
      model: 'text-embedding-v3',
      apiKey: '',
      baseUrl: '',
      chunkStrategy: 'sentence',
      chunkSize: 800,
      chunkOverlap: 100,
      normalizeEmbedding: true,
      batchSize: 8,
      rerankEnabled: false,
      rerankModel: '',
      rerankTopK: 10,
      rerankProvider: ''
    }
  }
}

function saveEmbeddingConfig(config) {
  localStorage.setItem(EMBEDDING_CONFIG_KEY, JSON.stringify(config || {}))
}

function loadRetrievalConfig() {
  try {
    const raw = localStorage.getItem(RETRIEVAL_CONFIG_KEY)
    if (!raw) {
      return {
        topK: 5,
        keywordWeight: 0.5,
        vectorWeight: 0.5,
        bm25Enabled: true,
        bm25K1: 1.5,
        bm25B: 0.75,
        rerankEnabled: false,
        rerankTopN: 3,
        enableDeduplication: true,
        strategy: 'hybrid'
      }
    }
    const parsed = JSON.parse(raw)
    return {
      topK: Number.isFinite(parsed?.topK) ? parsed.topK : 5,
      keywordWeight: Number.isFinite(parsed?.keywordWeight) ? parsed.keywordWeight : 0.5,
      vectorWeight: Number.isFinite(parsed?.vectorWeight) ? parsed.vectorWeight : 0.5,
      bm25Enabled: parsed?.bm25Enabled !== undefined ? parsed.bm25Enabled : true,
      bm25K1: Number.isFinite(parsed?.bm25K1) ? parsed.bm25K1 : 1.5,
      bm25B: Number.isFinite(parsed?.bm25B) ? parsed.bm25B : 0.75,
      rerankEnabled: parsed?.rerankEnabled !== undefined ? parsed.rerankEnabled : false,
      rerankTopN: Number.isFinite(parsed?.rerankTopN) ? parsed.rerankTopN : 3,
      enableDeduplication: parsed?.enableDeduplication !== undefined ? parsed.enableDeduplication : true,
      strategy: parsed?.strategy || 'hybrid'
    }
  } catch (e) {
    return {
      topK: 5,
      keywordWeight: 0.5,
      vectorWeight: 0.5,
      bm25Enabled: true,
      bm25K1: 1.5,
      bm25B: 0.75,
      rerankEnabled: false,
      rerankTopN: 3,
      enableDeduplication: true,
      strategy: 'hybrid'
    }
  }
}

function saveRetrievalConfig(config) {
  localStorage.setItem(RETRIEVAL_CONFIG_KEY, JSON.stringify(config || {}))
}

function chunkText(text, strategy = 'sentence', maxLen = 800, overlap = 100) {
  const t = (text || '').trim()
  if (!t) return []

  if (strategy === 'fixed') {
    // Fixed-size chunking with overlap
    const parts = []
    let start = 0
    while (start < t.length) {
      parts.push(t.slice(start, start + maxLen))
      start += maxLen - overlap
    }
    return parts
  }

  if (strategy === 'paragraph') {
    // Paragraph-based chunking
    const paragraphs = t.split(/\n\s*\n/)
    const parts = []
    let buffer = ''
    for (const para of paragraphs) {
      if ((buffer + para).length > maxLen && buffer) {
        parts.push(buffer.trim())
        // Keep overlap
        const lastSentences = buffer.slice(-overlap)
        buffer = lastSentences + '\n' + para
      } else {
        buffer += (buffer ? '\n\n' : '') + para
      }
    }
    if (buffer.trim()) parts.push(buffer.trim())
    return parts
  }

  // Default: sentence-based chunking
  const parts = []
  let buffer = ''
  const sentences = t.split(/(?<=[。！？!?.\n])/)
  for (const s of sentences) {
    if ((buffer + s).length > maxLen && buffer) {
      parts.push(buffer)
      // Keep overlap (last part of previous buffer)
      const overlapText = buffer.slice(-Math.min(overlap, buffer.length))
      buffer = overlapText + s
    } else {
      buffer += s
    }
  }
  if (buffer) parts.push(buffer)
  return parts
}

async function embedChunk(text, config) {
  const content = (text || '').trim()
  if (!content) return []
  const { embedWithModelScope } = await import('../api/embeddings')
  return embedWithModelScope({
    apiKey: config?.apiKey || '',
    model: config?.model || 'text-embedding-v3',
    baseUrl: config?.baseUrl || '',
    input: content
  })
}

function cosineSimilarity(a = [], b = []) {
  if (!a.length || !b.length || a.length !== b.length) return 0
  let dot = 0
  let na = 0
  let nb = 0
  for (let i = 0; i < a.length; i++) {
    dot += a[i] * b[i]
    na += a[i] * a[i]
    nb += b[i] * b[i]
  }
  if (!na || !nb) return 0
  return dot / (Math.sqrt(na) * Math.sqrt(nb))
}

function keywordSimilarity(query, text) {
  const q = (query || '').toLowerCase().split(/[\s,，。；;]+/).filter(Boolean)
  const t = (text || '').toLowerCase()
  if (!q.length || !t) return 0
  let hit = 0
  q.forEach((word) => {
    if (t.includes(word)) hit += 1
  })
  return hit / q.length
}
