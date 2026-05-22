#!/bin/bash
# Skill 01: 需求分析
# 生成项目文档：API文档、数据库Schema、数据模型
# 自动创建变更记录

TASK_ID="$1"
DEMAND="$2"
TASK_DIR=".harness/tasks/task-${TASK_ID}"
DOCS_DIR=".harness/docs"
CHANGES_DIR=".harness/changes"

mkdir -p "$DOCS_DIR"
mkdir -p "$CHANGES_DIR"

CHANGE_ID="CHG-$(date +%Y%m%d%H%M%S)"
CREATE_TIME=$(date "+%Y-%m-%d %H:%M:%S")

echo -e "📋  分析需求并生成项目文档..."

analyze_demand() {
    local demand="$1"

    if echo "$demand" | grep -qi "账号\|用户\|登录\|管理"; then
        echo "USER_ACCOUNT"
    elif echo "$demand" | grep -qi "商品\|产品"; then
        echo "PRODUCT"
    elif echo "$demand" | grep -qi "订单"; then
        echo "ORDER"
    else
        echo "GENERIC"
    fi
}

analyze_change_type() {
    local demand="$1"

    if echo "$demand" | grep -qi "修复\|bug\|错误"; then
        echo "Bug Fix"
    elif echo "$demand" | grep -qi "重构\|优化\|改进"; then
        echo "Refactoring"
    else
        echo "Feature"
    fi
}

TYPE=$(analyze_demand "$DEMAND")
CHANGE_TYPE=$(analyze_change_type "$DEMAND")

# 创建变更记录
cat > "$CHANGES_DIR/${CHANGE_ID}.md" <<EOF
# 变更记录 - ${CHANGE_ID}

## 基本信息

| 字段 | 内容 |
|------|------|
| 变更ID | ${CHANGE_ID} |
| 变更类型 | ${CHANGE_TYPE} |
| 状态 | In Progress |
| 创建时间 | ${CREATE_TIME} |
| 来源需求 | ${DEMAND} |

## 变更详情

### 变更描述
${DEMAND}

### 变更原因
满足用户提出的业务需求

### 影响范围
- 后端模块: 待定
- 前端模块: 待定
- 数据库: 待定

## 关联文档

- API规范: \`.harness/docs/api-spec.md\`
- 数据库设计: \`.harness/docs/database-schema.md\`
- 项目上下文: \`.harness/docs/project-context.md\`

## 任务执行记录

### Skill 01: 需求分析
- 状态: ✅ 完成
- 执行时间: ${CREATE_TIME}
- 产出: 项目文档、变更记录

### Skill 02-06: 待执行
- 状态: Pending

---

*由 Harness Engineering 智能体工作流自动生成*
EOF

# 更新汇总文档
SUMMARY_FILE="$CHANGES_DIR/SUMMARY.md"
if [ -f "$SUMMARY_FILE" ]; then
    # 移除注释模板行，添加新的变更记录
    sed -i '' "/<!-- | CHG-001 |/d" "$SUMMARY_FILE"
    sed -i '' "/<!-- - \[CHG-001\]/d" "$SUMMARY_FILE"
    sed -i '' "/<!-- - \[CHG-001\]/d" "$SUMMARY_FILE"
    sed -i '' "s/| CHG-001 | Feature | 后台账号管理功能 | Completed | 2026-05-22 |/| CHG-001 | Feature | 后台账号管理功能 | Completed | 2026-05-22 |\n| ${CHANGE_ID} | ${CHANGE_TYPE} | ${DEMAND} | In Progress | ${CREATE_TIME} |/" "$SUMMARY_FILE"
fi

case $TYPE in
"USER_ACCOUNT")
    cat > "$DOCS_DIR/api-spec.md" <<'EOF'
# API 规范文档

## 认证接口

### POST /api/auth/login
登录接口

**请求体:**
```json
{
  "username": "string",
  "encryptedPassword": "string (RSA加密)"
}
```

**响应:**
```json
{
  "code": 200,
  "message": "登录成功",
  "data": {
    "token": "string",
    "tokenType": "Bearer",
    "expiresIn": 86400000,
    "user": {
      "id": "number",
      "username": "string",
      "realName": "string",
      "role": "string",
      "superAdmin": "boolean"
    }
  }
}
```

### GET /api/auth/public-key
获取RSA公钥

**响应:**
```json
{
  "code": 200,
  "data": { "publicKey": "string" }
}
```

## 用户管理接口

### GET /api/users
获取所有用户（需SUPER_ADMIN权限）

### POST /api/users
创建用户（需SUPER_ADMIN权限）

**请求体:**
```json
{
  "username": "string",
  "password": "string",
  "realName": "string",
  "phone": "string",
  "email": "string",
  "role": "ADMIN|USER"
}
```

### GET /api/users/{username}
根据用户名获取用户信息
EOF

    cat > "$DOCS_DIR/database-schema.md" <<'EOF'
# 数据库设计文档

## sys_user 表

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGINT | PK, AUTO_INCREMENT | 主键 |
| username | VARCHAR(50) | UNIQUE, NOT NULL | 用户名 |
| password | VARCHAR(255) | NOT NULL | 密码(BCrypt加密) |
| real_name | VARCHAR(100) | | 真实姓名 |
| phone | VARCHAR(20) | | 手机号 |
| email | VARCHAR(100) | | 邮箱 |
| role | VARCHAR(20) | NOT NULL | 角色 |
| enabled | BOOLEAN | NOT NULL DEFAULT TRUE | 是否启用 |
| account_non_locked | BOOLEAN | NOT NULL DEFAULT TRUE | 是否锁定 |
| account_non_expired | BOOLEAN | NOT NULL DEFAULT TRUE | 是否过期 |
| credentials_non_expired | BOOLEAN | NOT NULL DEFAULT TRUE | 凭证是否过期 |
| super_admin | BOOLEAN | NOT NULL DEFAULT FALSE | 是否超级管理员 |
| last_login_ip | VARCHAR(50) | | 最后登录IP |
| last_login_time | DATETIME | | 最后登录时间 |
| create_time | DATETIME | NOT NULL | 创建时间 |
| update_time | DATETIME | | 更新时间 |

## 角色说明

- SUPER_ADMIN: 超级管理员，拥有所有权限
- ADMIN: 管理员
- USER: 普通用户
EOF
    ;;
*)
    echo "GENERIC mode - no specific docs generated"
    ;;
esac

cat > "$DOCS_DIR/project-context.md" <<EOF
# 项目上下文

## 技术栈

- **后端:** Spring Boot 3.2.x, Java 21, Spring Security, JPA
- **前端:** Vue 3, TypeScript, Vite, Pinia
- **数据库:** MySQL 8.0
- **认证:** JWT + RSA加密

## 项目结构

\`\`\`
backend/
├── src/main/java/com/harness/admin/
│   ├── config/          # 配置类
│   ├── controller/      # REST控制器
│   ├── dto/            # 数据传输对象
│   ├── entity/         # JPA实体
│   ├── repository/     # 数据访问层
│   ├── security/       # 安全相关(JWT, 过滤器)
│   ├── service/        # 业务逻辑
│   └── util/           # 工具类

frontend/
├── src/
│   ├── api/           # API调用
│   ├── router/        # 路由配置
│   ├── store/         # Pinia状态管理
│   ├── utils/         # 工具函数
│   └── views/         # 页面组件
\`\`\`

## 安全机制

1. 登录密码在前端使用RSA公钥加密传输
2. 后端使用BCrypt存储密码
3. 认证使用JWT Token
4. 敏感接口需要SUPER_ADMIN权限
EOF

cat > "$TASK_DIR/01-demand-analysis.md" <<EOF
# 需求分析报告 - Task $TASK_ID

## 原始需求
$DEMAND

## 需求类型
$TYPE

## 变更记录
- 变更ID: ${CHANGE_ID}
- 状态: In Progress

## 生成文档
- ✅ .harness/changes/${CHANGE_ID}.md - 变更记录
- ✅ .harness/changes/SUMMARY.md - 变更历史汇总
- ✅ .harness/docs/api-spec.md - API规范
- ✅ .harness/docs/database-schema.md - 数据库设计
- ✅ .harness/docs/project-context.md - 项目上下文

## 影响范围
- 后端模块: UserService, AuthController, UserController
- 前端模块: Login页面, UserManagement页面
- 数据库: sys_user表

## 结论
✅ 需求分析完成，已生成项目文档供后续AI理解项目
EOF

echo -e "✅  需求分析完成"
echo -e "   📄  变更记录: $CHANGES_DIR/${CHANGE_ID}.md"
echo -e "   📄  变更历史: $CHANGES_DIR/SUMMARY.md"
echo -e "   📄  API文档: $DOCS_DIR/api-spec.md"
echo -e "   📄  数据库Schema: $DOCS_DIR/database-schema.md"
echo -e "   📄  项目上下文: $DOCS_DIR/project-context.md"