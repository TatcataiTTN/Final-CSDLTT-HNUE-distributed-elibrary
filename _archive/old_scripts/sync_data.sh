#!/usr/bin/env bash
# ============================================================================
# Sync Data Script - Đồng bộ dữ liệu từ Branches về Central Hub
# ============================================================================

echo "=== SYNC DATA: Branches -> Central Hub ==="
echo ""

# Check mongosh
if ! command -v mongosh &> /dev/null; then
    echo "ERROR: mongosh not found. Please install MongoDB Shell."
    exit 1
fi

echo "[1/3] Syncing customers from branches..."

mongosh --quiet --eval "
var central = db.getSiblingDB('Nhasach');

// Clear and sync customers
central.customers.deleteMany({});

var branches = [
    {db: 'NhasachHaNoi', branch_id: 'HN', name: 'Ha Noi'},
    {db: 'NhasachDaNang', branch_id: 'DN', name: 'Da Nang'},
    {db: 'NhasachHoChiMinh', branch_id: 'HCM', name: 'Ho Chi Minh'}
];

var totalCustomers = 0;

branches.forEach(function(branch) {
    var branchDb = db.getSiblingDB(branch.db);
    var customers = branchDb.users.find({role: 'customer'}).toArray();

    customers.forEach(function(cust) {
        central.customers.insertOne({
            original_id: cust._id,
            username: cust.username,
            display_name: cust.display_name || cust.username,
            email: cust.email || '',
            role: cust.role,
            balance: cust.balance || 0,
            branch_id: branch.branch_id,
            branch_name: branch.name,
            source_db: branch.db,
            synced_at: new Date()
        });
        totalCustomers++;
    });
});

print('   Synced ' + totalCustomers + ' customers');
"

echo "[2/3] Syncing orders from branches..."

mongosh --quiet --eval "
var central = db.getSiblingDB('Nhasach');

// Clear and sync orders
central.orders_central.deleteMany({});

var branches = [
    {db: 'NhasachHaNoi', branch_id: 'HN'},
    {db: 'NhasachDaNang', branch_id: 'DN'},
    {db: 'NhasachHoChiMinh', branch_id: 'HCM'}
];

var totalOrders = 0;

branches.forEach(function(branch) {
    var branchDb = db.getSiblingDB(branch.db);
    var orders = branchDb.orders.find({}).toArray();

    orders.forEach(function(order) {
        order.source_branch = branch.branch_id;
        order.source_db = branch.db;
        order.synced_at = new Date();
        central.orders_central.insertOne(order);
        totalOrders++;
    });
});

print('   Synced ' + totalOrders + ' orders');
"

echo "[3/3] Verifying sync..."

mongosh --quiet --eval "
var central = db.getSiblingDB('Nhasach');
print('');
print('=== SYNC RESULTS ===');
print('   customers: ' + central.customers.countDocuments());
print('   orders_central: ' + central.orders_central.countDocuments());
print('   books: ' + central.books.countDocuments());
print('   users: ' + central.users.countDocuments());
"

echo ""
echo "=== SYNC COMPLETED ==="
