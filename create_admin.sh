#!/bin/bash

# =============================================================================
# CREATE ADMIN USER SCRIPT
# =============================================================================
# Tạo admin user với password đơn giản cho tất cả các branch
# =============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}👤 CREATE ADMIN USERS${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Password: admin123
# Hashed with bcrypt (cost 10)
HASHED_PASSWORD='$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi'

echo -e "${YELLOW}Creating admin users with credentials:${NC}"
echo -e "  Username: ${GREEN}admin${NC}"
echo -e "  Password: ${GREEN}admin123${NC}\n"

# Create admin for Central (mongo1)
echo -e "${YELLOW}Creating admin for Central (mongo1)...${NC}"
docker exec mongo1 mongo Nhasach --quiet --eval "
db.users.updateOne(
  { username: 'admin' },
  { 
    \$set: {
      username: 'admin',
      password: '$HASHED_PASSWORD',
      email: 'admin@nhasach.com',
      fullName: 'Administrator',
      role: 'admin',
      createdAt: new Date(),
      updatedAt: new Date()
    }
  },
  { upsert: true }
);
print('Admin created/updated for Central');
"

# Create admin for Hà Nội (mongo2)
echo -e "${YELLOW}Creating admin for Hà Nội (mongo2)...${NC}"
docker exec mongo2 mongo NhasachHaNoi --quiet --eval "
db.users.updateOne(
  { username: 'admin' },
  { 
    \$set: {
      username: 'admin',
      password: '$HASHED_PASSWORD',
      email: 'admin@hanoi.com',
      fullName: 'Administrator Hà Nội',
      role: 'admin',
      createdAt: new Date(),
      updatedAt: new Date()
    }
  },
  { upsert: true }
);
print('Admin created/updated for Hà Nội');
"

echo -e "\n${GREEN}✅ Admin users created successfully!${NC}\n"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}📝 LOGIN CREDENTIALS${NC}"
echo -e "${BLUE}========================================${NC}\n"

echo -e "${YELLOW}All Branches:${NC}"
echo -e "  Username: ${GREEN}admin${NC}"
echo -e "  Password: ${GREEN}admin123${NC}\n"

echo -e "${YELLOW}Login URLs:${NC}"
echo -e "  • Central:  http://localhost:8000/php/dangnhap.php"
echo -e "  • Hà Nội:   http://localhost:8002/php/dangnhap.php"
echo -e "  • Đà Nẵng:  http://localhost:8003/php/dangnhap.php"
echo -e "  • TP.HCM:   http://localhost:8004/php/dangnhap.php\n"

echo -e "${YELLOW}Data Center Dashboard:${NC}"
echo -e "  • http://localhost:8002/php/dashboard_datacenter.php\n"

echo -e "${GREEN}✅ Done!${NC}"

