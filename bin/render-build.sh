#!/usr/bin/env bash
# exit on error
set -o errexit

echo "Render 빌드 시작..."

# 플랫폼 추가 (Linux 환경 지원)
echo "Linux 플랫폼 지원 추가 중..."
bundle lock --add-platform x86_64-linux

# Bundler 설치
echo "Dependencies 설치 중..."
bundle install

# 데이터베이스 마이그레이션
echo "데이터베이스 마이그레이션 실행 중..."
bundle exec rails db:migrate

# 시드 데이터 로드 (필요시)
if [ -f db/seeds.rb ]; then
  echo "시드 데이터 로드 중..."
  bundle exec rails db:seed
fi

# 애셋 프리컴파일
echo "애셋 프리컴파일 중..."
bundle exec rails assets:precompile
bundle exec rails assets:clean

echo "빌드 완료!"