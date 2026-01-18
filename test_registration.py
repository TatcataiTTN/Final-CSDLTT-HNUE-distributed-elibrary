#!/usr/bin/env python3
import requests
import time
from pymongo import MongoClient

print("=" * 50)
print("🔍 REGISTRATION DEBUG TEST")
print("=" * 50)
print()

ports = [
    {'http': 8001, 'mongo': 27017, 'db': 'Nhasach', 'name': 'Central Hub'},
    {'http': 8002, 'mongo': 27018, 'db': 'NhasachHaNoi', 'name': 'HaNoi'},
    {'http': 8003, 'mongo': 27019, 'db': 'NhasachDaNang', 'name': 'DaNang'},
    {'http': 8004, 'mongo': 27020, 'db': 'NhasachHoChiMinh', 'name': 'HoChiMinh'},
]

test_username = f"pytest_{int(time.time())}"
results = []

for port in ports:
    print("=" * 50)
    print(f"Testing: {port['name']} (Port {port['http']})")
    print("=" * 50)
    
    username = f"{test_username}_{port['http']}"
    result = {'name': port['name'], 'port': port['http']}
    
    # Step 1: Check MongoDB
    try:
        client = MongoClient(f"mongodb://localhost:{port['mongo']}")
        db = client[port['db']]
        count_before = db.users.count_documents({})
        print(f"✅ MongoDB connected: {count_before} users")
        result['mongo_ok'] = True
    except Exception as e:
        print(f"❌ MongoDB failed: {e}")
        result['mongo_ok'] = False
        results.append(result)
        continue
    
    # Step 2: Submit registration
    print(f"Submitting registration for: {username}")
    
    try:
        response = requests.post(
            f"http://localhost:{port['http']}/php/dangky.php",
            data={'username': username, 'password': 'test123'},
            timeout=5
        )
        print(f"HTTP Response: {response.status_code}")
        result['http_code'] = response.status_code
        
        # Check response content
        content = response.text.lower()
        has_success = any(word in content for word in ['thành công', 'success', 'đăng nhập ngay'])
        has_duplicate = any(word in content for word in ['đã tồn tại', 'already exists'])
        
        if has_success:
            print("✅ Response contains SUCCESS message")
            result['message_ok'] = True
        elif has_duplicate:
            print("⚠️  Response contains DUPLICATE message")
            result['message_ok'] = 'duplicate'
        else:
            print("❌ Response does NOT contain success message")
            result['message_ok'] = False
            # Show preview
            preview = response.text[:500].replace('\n', ' ')
            print(f"Preview: {preview}...")
        
    except Exception as e:
        print(f"❌ HTTP request failed: {e}")
        result['http_ok'] = False
        results.append(result)
        continue
    
    # Step 3: Wait and check database
    time.sleep(1)
    
    try:
        count_after = db.users.count_documents({})
        user = db.users.find_one({'username': username})
        
        print(f"Users after: {count_after} ", end='')
        if count_after > count_before:
            print("(+1)")
            result['user_created'] = True
        else:
            print("(no change)")
            result['user_created'] = False
        
        if user:
            print(f"✅ User '{username}' EXISTS in database")
            print(f"   - ID: {user['_id']}")
            print(f"   - Role: {user['role']}")
            result['user_found'] = True
        else:
            print(f"❌ User '{username}' NOT FOUND in database")
            result['user_found'] = False
    except Exception as e:
        print(f"❌ MongoDB check failed: {e}")
        result['user_found'] = False
    
    # Conclusion
    print("\n🎯 CONCLUSION: ", end='')
    if result.get('user_found') and result.get('message_ok') is True:
        print("✅ FULLY WORKING")
        result['status'] = 'PASS'
    elif result.get('user_found') and not result.get('message_ok'):
        print("⚠️  WORKS but message not shown (UI issue)")
        result['status'] = 'PARTIAL'
    else:
        print("❌ FAILED - User not created")
        result['status'] = 'FAIL'
    
    results.append(result)
    print()

# Final Summary
print("=" * 50)
print("📊 FINAL SUMMARY")
print("=" * 50)
print()

pass_count = sum(1 for r in results if r.get('status') == 'PASS')
partial_count = sum(1 for r in results if r.get('status') == 'PARTIAL')
fail_count = sum(1 for r in results if r.get('status') == 'FAIL')

for r in results:
    status = r.get('status', 'UNKNOWN')
    print(f"{r['name']} (Port {r['port']}): ", end='')
    
    if status == 'PASS':
        print("✅ PASS")
    elif status == 'PARTIAL':
        print("⚠️  PARTIAL (works but no message)")
    else:
        print("❌ FAIL")

print()
print(f"Total: {len(results)} sites")
print(f"✅ Pass: {pass_count}")
print(f"⚠️  Partial: {partial_count}")
print(f"❌ Fail: {fail_count}")

success_rate = round(((pass_count + partial_count) / len(results)) * 100)
print(f"\nSuccess Rate: {success_rate}%")

if pass_count == len(results):
    print("\n🎉 ALL SITES WORKING PERFECTLY!")
elif (pass_count + partial_count) == len(results):
    print("\n⚠️  ALL SITES FUNCTIONAL (some UI issues)")
else:
    print("\n❌ SOME SITES HAVE ISSUES")

