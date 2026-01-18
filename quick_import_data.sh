#!/bin/bash

# =============================================================================
# QUICK IMPORT DATA SCRIPT
# =============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}📥 IMPORTING DATA${NC}"
echo -e "${BLUE}========================================${NC}\n"

DATA_DIR="Data MONGODB export .json"

# Import to Central (mongo1)
echo -e "${YELLOW}Importing to Central (mongo1)...${NC}"
cat "$DATA_DIR/Nhasach.books.json" | docker exec -i mongo1 mongoimport --db Nhasach --collection books --drop --jsonArray
cat "$DATA_DIR/Nhasach.users.json" | docker exec -i mongo1 mongoimport --db Nhasach --collection users --drop --jsonArray
echo -e "${GREEN}✅ Central data imported${NC}\n"

# Import to Hà Nội (mongo2)
echo -e "${YELLOW}Importing to Hà Nội (mongo2)...${NC}"
cat "$DATA_DIR/NhasachHaNoi.books.json" | docker exec -i mongo2 mongoimport --db NhasachHaNoi --collection books --drop --jsonArray
cat "$DATA_DIR/NhasachHaNoi.users.json" | docker exec -i mongo2 mongoimport --db NhasachHaNoi --collection users --drop --jsonArray
cat "$DATA_DIR/NhasachHaNoi.orders.json" | docker exec -i mongo2 mongoimport --db NhasachHaNoi --collection orders --drop --jsonArray
cat "$DATA_DIR/NhasachHaNoi.carts.json" | docker exec -i mongo2 mongoimport --db NhasachHaNoi --collection carts --drop --jsonArray
echo -e "${GREEN}✅ Hà Nội data imported${NC}\n"

# Import to Đà Nẵng (mongo3)
echo -e "${YELLOW}Importing to Đà Nẵng (mongo3)...${NC}"
cat "$DATA_DIR/NhasachDaNang.books.json" | docker exec -i mongo3 mongoimport --db NhasachDaNang --collection books --drop --jsonArray
cat "$DATA_DIR/NhasachDaNang.users.json" | docker exec -i mongo3 mongoimport --db NhasachDaNang --collection users --drop --jsonArray
cat "$DATA_DIR/NhasachDaNang.orders.json" | docker exec -i mongo3 mongoimport --db NhasachDaNang --collection orders --drop --jsonArray
echo -e "${GREEN}✅ Đà Nẵng data imported${NC}\n"

# Import to TP.HCM (mongo4)
echo -e "${YELLOW}Importing to TP.HCM (mongo4)...${NC}"
cat "$DATA_DIR/NhasachHoChiMinh.users.json" | docker exec -i mongo4 mongoimport --db NhasachHoChiMinh --collection users --drop --jsonArray
cat "$DATA_DIR/NhasachHoChiMinh.orders.json" | docker exec -i mongo4 mongoimport --db NhasachHoChiMinh --collection orders --drop --jsonArray
cat "$DATA_DIR/NhasachHoChiMinh.carts.json" | docker exec -i mongo4 mongoimport --db NhasachHoChiMinh --collection carts --drop --jsonArray
echo -e "${GREEN}✅ TP.HCM data imported${NC}\n"

# Verify counts
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}📊 VERIFICATION${NC}"
echo -e "${BLUE}========================================${NC}\n"

echo -e "${YELLOW}Central (mongo1):${NC}"
docker exec mongo1 mongo Nhasach --quiet --eval "print('Books: ' + db.books.countDocuments({})); print('Users: ' + db.users.countDocuments({}));"

echo -e "\n${YELLOW}Hà Nội (mongo2):${NC}"
docker exec mongo2 mongo NhasachHaNoi --quiet --eval "print('Books: ' + db.books.countDocuments({})); print('Users: ' + db.users.countDocuments({})); print('Orders: ' + db.orders.countDocuments({}));"

echo -e "\n${YELLOW}Đà Nẵng (mongo3):${NC}"
docker exec mongo3 mongo NhasachDaNang --quiet --eval "print('Books: ' + db.books.countDocuments({})); print('Users: ' + db.users.countDocuments({})); print('Orders: ' + db.orders.countDocuments({}));"

echo -e "\n${YELLOW}TP.HCM (mongo4):${NC}"
docker exec mongo4 mongo NhasachHoChiMinh --quiet --eval "print('Users: ' + db.users.countDocuments({})); print('Orders: ' + db.orders.countDocuments({}));"

echo -e "\n${GREEN}✅ Data import completed!${NC}"
echo -e "\n${BLUE}Now you can access:${NC}"
echo -e "  • Data Center Dashboard: http://localhost:8002/php/dashboard_datacenter.php"
echo -e "  • Hà Nội: http://localhost:8002/php/dangnhap.php"

