const { remote } = require('webdriverio');
const path = require('path');

const APK_PATH = path.resolve(__dirname, 'build/app/outputs/flutter-apk/app-profile.apk');

const capabilities = {
  platformName: 'Android',
  'appium:automationName': 'FlutterIntegration',
  'appium:app': APK_PATH,
  'appium:deviceName': 'emulator-5554',
  'appium:newCommandTimeout': 120,
};

const wdOpts = {
  hostname: '127.0.0.1',
  port: 4723,
  logLevel: 'error', // reduce noise
  capabilities,
};

// Helper: find element by Flutter key using raw protocol call
async function byKey(driver, keyName) {
  const el = await driver.findElement('-flutter key', keyName);
  return driver.$(el);
}

// Helper: wait for element by Flutter key to appear
async function waitForKey(driver, keyName, timeout = 8000) {
  const start = Date.now();
  while (Date.now() - start < timeout) {
    try {
      const el = await driver.findElement('-flutter key', keyName);
      return driver.$(el);
    } catch {
      await driver.pause(500);
    }
  }
  throw new Error(`Timed out waiting for element with key: ${keyName}`);
}

async function runTest() {
  console.log('🚀 Starting login test...');
  const driver = await remote(wdOpts);

  try {
    // ── Test 1: Invalid credentials show error ──────────────────────────
    console.log('\n📋 Test 1: Invalid credentials');

    const emailField = await byKey(driver, 'email_input');
    await emailField.click();
    await emailField.setValue('wrong@example.com');

    const passwordField = await byKey(driver, 'password_input');
    await passwordField.click();
    await passwordField.setValue('wrongpass');

    const loginButton = await byKey(driver, 'login_button');
    await loginButton.click();

    await waitForKey(driver, 'error_message');
    console.log('✅ Test 1 passed: Error shown for invalid credentials');

    // ── Test 2: Valid credentials navigate to home ──────────────────────
    console.log('\n📋 Test 2: Valid credentials');

    const emailField2 = await byKey(driver, 'email_input');
    await emailField2.clearValue();
    await emailField2.setValue('test@example.com');

    const passwordField2 = await byKey(driver, 'password_input');
    await passwordField2.clearValue();
    await passwordField2.setValue('password123');

    await loginButton.click();

    await waitForKey(driver, 'home_screen');
    console.log('✅ Test 2 passed: Navigated to home screen');

    console.log('\n🎉 All tests passed!');
  } catch (err) {
    console.error('\n❌ Test failed:', err.message);
    process.exit(1);
  } finally {
    await driver.deleteSession();
    console.log('🔒 Session closed');
  }
}

runTest();
