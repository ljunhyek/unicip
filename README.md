# 특허 관리 시스템 (Patent Management System)

특허청 API와 연동하여 사용자별 특허 정보를 관리하고 연차료 납부 현황을 추적하는 Rails 기반 웹 애플리케이션입니다.

## 주요 기능

### 사용자 관리
- 회원 가입 및 로그인 (Devise 기반)
- 사용자 유형: 개인, 법인, 법인 발명자
- 특허청 고객번호 연동

### 특허 정보 관리
- 특허청 KIPRIS API 연동으로 실시간 특허 정보 동기화
- 출원 현황, 등록 현황 조회
- 특허 문서 (의견서, 공개전문, 공고전문) 관리
- 특허 상태 변경 이력 추적

### 연차료 관리
- 자동 연차료 스케줄 생성
- 납부 마감일 알림
- 미납/연체 현황 조회
- 가산금 자동 계산
- 납부 기록 관리

### 알림 시스템
- 이메일 알림 (연차료 납부 알림)
- 사용자 맞춤 알림 설정

### 관리자 기능
- 사용자 관리
- 일괄 동기화 작업
- 시스템 로그 관리

## 기술 스택

- **Backend**: Ruby on Rails 7.0
- **Database**: PostgreSQL
- **Authentication**: Devise
- **Background Jobs**: Sidekiq
- **API Integration**: HTTParty (KIPRIS API)
- **Frontend**: Rails Views with Turbo
- **Deployment**: Render
- **Version Control**: Git

## 환경 설정

### 1. 의존성 설치

```bash
bundle install
```

### 2. 환경변수 설정

`.env` 파일을 생성하고 다음 변수들을 설정하세요:

```env
# Database Configuration
DATABASE_USERNAME=postgres
DATABASE_PASSWORD=your_password_here
DATABASE_HOST=localhost
DATABASE_PORT=5432

# KIPRIS API Configuration
KIPRIS_API_KEY=your_kipris_api_key_here
KIPRIS_API_URL=http://plus.kipris.or.kr/openapi/rest

# Email Configuration
SMTP_SERVER=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your_email@gmail.com
SMTP_PASSWORD=your_app_password

# Redis Configuration (for Sidekiq)
REDIS_URL=redis://localhost:6379/0

# Application Settings
SECRET_KEY_BASE=your_secret_key_base_here
RAILS_ENV=development
```

### 3. 데이터베이스 설정

```bash
# PostgreSQL 데이터베이스 생성
rails db:create

# 마이그레이션 실행
rails db:migrate

# 시드 데이터 로드 (옵션)
rails db:seed
```

### 4. Redis 및 Sidekiq 설정

백그라운드 작업을 위해 Redis와 Sidekiq이 필요합니다:

```bash
# Redis 서버 시작 (별도 터미널)
redis-server

# Sidekiq 워커 시작 (별도 터미널)
bundle exec sidekiq
```

### 5. Rails 서버 시작

```bash
rails server
```

브라우저에서 `http://localhost:3000`으로 접속하여 애플리케이션을 확인할 수 있습니다.

## 배포 (Render)

### 1. Git 저장소 설정

```bash
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/your-username/patent-management.git
git push -u origin main
```

### 2. Render 설정

1. [Render](https://render.com)에 로그인
2. GitHub 저장소 연결
3. `render.yaml` 설정이 자동으로 적용됨
4. 환경변수 설정:
   - `KIPRIS_API_KEY`
   - `SMTP_USERNAME`
   - `SMTP_PASSWORD`
   - `RAILS_MASTER_KEY`

### 3. 자동 배포

Git에 push할 때마다 자동으로 배포됩니다.

## 데이터베이스 스키마

### 주요 테이블

- `users`: 사용자 정보
- `patents`: 특허 정보
- `user_patents`: 사용자-특허 연결
- `annual_fees`: 연차료 정보
- `fee_payments`: 연차료 납부 기록
- `notifications`: 알림 기록
- `sync_jobs`: 동기화 작업
- `admin_users`: 관리자 계정

자세한 스키마는 `db/migrate/` 폴더의 마이그레이션 파일을 참조하세요.

## API 연동

### KIPRIS API

특허청 KIPRIS API를 통해 특허 정보를 동기화합니다:

- 출원인별 특허 목록 조회
- 특허 상세 정보 조회
- 문서 정보 조회

API 사용을 위해서는 특허청에서 발급받은 API 키가 필요합니다.

## 주요 워크플로우

### 1. 사용자 등록 및 특허 동기화

1. 사용자 회원가입 (특허청 고객번호 입력)
2. 대시보드에서 "특허 정보 동기화" 클릭
3. 백그라운드에서 KIPRIS API 호출
4. 특허 정보 저장 및 연차료 스케줄 생성

### 2. 연차료 관리

1. 등록된 특허에 대해 자동으로 연차료 스케줄 생성
2. 매일 크론잡으로 납부 마감일 확인
3. 알림 발송 (30일 전, 7일 전, 1일 전)
4. 연체 시 가산금 자동 계산

### 3. 관리자 일괄 동기화

1. 관리자 로그인
2. "전체 사용자 일괄 동기화" 실행
3. 모든 사용자의 특허 정보 업데이트

## 개발

### 테스트 실행

```bash
# RSpec 테스트 실행
bundle exec rspec

# 특정 테스트 파일 실행
bundle exec rspec spec/models/user_spec.rb
```

### 코드 스타일 검사

```bash
# Rubocop 실행
bundle exec rubocop

# 자동 수정
bundle exec rubocop -a
```

## 라이선스

MIT License

## 지원

이슈나 질문이 있으시면 GitHub Issues를 통해 문의해 주세요.
