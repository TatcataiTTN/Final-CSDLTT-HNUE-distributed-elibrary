# Test Suite Documentation

## Overview

This test suite provides comprehensive testing and debugging for the Distributed e-Library System.

## Test Structure

```
tests/
├── unit/                    # Unit tests (future)
├── integration/             # Integration tests
│   └── interface_test.sh    # Test all web interfaces
├── e2e/                     # End-to-end tests (future)
├── debug/                   # Debug and diagnostic tools
│   ├── deep_debug.sh        # Deep system analysis
│   └── conflict_detection.sh # Version conflict detection
├── reports/                 # Test reports (auto-generated)
└── health_check.sh          # System health check

run_all_tests.sh             # Master test runner
```

## Quick Start

### Run All Tests
```bash
./run_all_tests.sh
```

### Run Individual Tests

#### 1. Health Check
```bash
./tests/health_check.sh
```
Tests:
- Environment (PHP, Docker, Composer)
- Docker containers
- MongoDB connections
- Replica set status
- Database data
- PHP servers
- Web interfaces
- API endpoints
- PHP dependencies

#### 2. Conflict Detection
```bash
./tests/debug/conflict_detection.sh
```
Detects:
- PHP version compatibility
- MongoDB extension version
- Composer package conflicts
- MongoDB server version
- PHP configuration issues
- Syntax errors
- Docker version

#### 3. Deep Debug
```bash
./tests/debug/deep_debug.sh
```
Analyzes:
- PHP version & extensions
- Composer dependencies
- Connection.php configuration
- PHP MongoDB connections
- API endpoints (verbose)
- PHP error logs
- File permissions
- Port conflicts
- Docker logs
- Replica set detailed status

#### 4. Interface Testing
```bash
./tests/integration/interface_test.sh
```
Tests all pages on all ports:
- Homepage
- Login/Register
- Dashboard
- Book Management
- User Management
- Shopping Cart
- Order History
- All API endpoints

## Test Reports

All test reports are saved to `tests/reports/` with timestamps:
- `health_check_YYYYMMDD_HHMMSS.log`
- `conflict_detection_YYYYMMDD_HHMMSS.log`
- `debug_trace_YYYYMMDD_HHMMSS.log`
- `interface_test_YYYYMMDD_HHMMSS.log`
- `master_test_YYYYMMDD_HHMMSS.log`

## Common Issues & Solutions

### Issue: PHP MongoDB Extension Not Loaded
```bash
# Install extension
pecl install mongodb

# Add to php.ini
echo "extension=mongodb.so" >> $(php --ini | grep "Loaded Configuration" | sed -e "s|.*:\s*||")

# Verify
php -m | grep mongodb
```

### Issue: Composer Dependencies Not Installed
```bash
# Install for all branches
for dir in Nhasach NhasachHaNoi NhasachDaNang NhasachHoChiMinh; do
    cd "$dir" && composer install && cd ..
done
```

### Issue: Docker Containers Not Running
```bash
# Start containers
docker-compose up -d

# Initialize replica set
./init-replica-set.sh

# Verify
docker ps
```

### Issue: PHP Servers Not Running
```bash
# Start all servers
./start_system.sh

# Or manually
php -S localhost:8001 -t Nhasach &
php -S localhost:8002 -t NhasachHaNoi &
php -S localhost:8003 -t NhasachDaNang &
php -S localhost:8004 -t NhasachHoChiMinh &
```

### Issue: Port Conflicts
```bash
# Check what's using the port
lsof -i :8001

# Kill PHP servers
pkill -f "php -S localhost:800"

# Restart
./start_system.sh
```

## Continuous Testing

### Watch Mode (Manual)
```bash
# Run tests every 60 seconds
watch -n 60 ./run_all_tests.sh
```

### Pre-commit Hook
```bash
# Add to .git/hooks/pre-commit
#!/bin/bash
./tests/health_check.sh
exit $?
```

## Test Coverage

### Current Coverage
- ✅ Environment checks
- ✅ Docker container health
- ✅ MongoDB connections
- ✅ Replica set verification
- ✅ Database data validation
- ✅ PHP server status
- ✅ Web interface accessibility
- ✅ API endpoint functionality
- ✅ Version conflict detection
- ✅ Configuration analysis
- ✅ Syntax error detection

### Future Coverage
- ⏳ Unit tests for PHP classes
- ⏳ Authentication flow testing
- ⏳ CRUD operation testing
- ⏳ Performance benchmarking
- ⏳ Load testing
- ⏳ Security testing

## Exit Codes

- `0` - All tests passed
- `1` - Some tests failed

## Troubleshooting

### All Tests Failing
1. Check if system is running: `./start_system.sh`
2. Verify Docker: `docker ps`
3. Check PHP servers: `lsof -i :8001`
4. Review logs in `tests/reports/`

### Specific Test Failing
1. Run the specific test with verbose output
2. Check the test report in `tests/reports/`
3. Review error messages
4. Fix the issue
5. Re-run the test

### Need More Details
Run deep debug for comprehensive analysis:
```bash
./tests/debug/deep_debug.sh
```

## Contributing

To add new tests:
1. Create test script in appropriate folder
2. Follow naming convention: `test_name.sh`
3. Add to `run_all_tests.sh`
4. Document in this README

## Support

For issues or questions:
1. Check test reports in `tests/reports/`
2. Run `./tests/debug/deep_debug.sh` for detailed analysis
3. Review SETUP_GUIDE.md for setup instructions
4. Check README.md for architecture details

