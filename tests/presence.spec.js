const { test, expect } = require('@playwright/test');

test('Presence indicator handles multiple joins, pluralization, and disconnects', async ({ browser }) => {
  // 1. Set up THREE isolated browsers
  const contextA = await browser.newContext();
  const contextB = await browser.newContext();
  const contextC = await browser.newContext();

  const pageA = await contextA.newPage();
  const pageB = await contextB.newPage();
  const pageC = await contextC.newPage();

  // Helper function so we don't write the same 7 lines of login code three times!
  async function loginAndJoin(page, playerName) {
    await page.goto('http://127.0.0.1:8080');
    await page.click('#open-player-modal-btn');
    await page.fill('#new-player-input', playerName);
    await page.click('#create-player-btn');
    await page.waitForTimeout(500);
    await page.click('#start-game-btn');
    
    // Type a letter to become an "active" guesser
    await expect(page.locator('#game-screen')).toBeVisible();
    await page.click('#key-a');
  }

  // Generate unique names to prevent database clashes
  const runId = Date.now().toString().slice(-4);
  
  // --- CASE 1: The Lonely Player (Zero State) ---
  await loginAndJoin(pageA, `Alpha ${runId}`);
  await expect(pageA.locator('#presence-count')).toHaveText('0 Others Guessing');

  // --- CASE 2: The Duel (Singular Grammar State) ---
  await loginAndJoin(pageB, `Bravo ${runId}`);
  
  // A should update to 1. B should see 1 right away.
  await expect(pageA.locator('#presence-count')).toHaveText('1 Other Guessing');
  await expect(pageB.locator('#presence-count')).toHaveText('1 Other Guessing');

  // --- CASE 3: The Crowd (Plural Grammar State) ---
  await loginAndJoin(pageC, `Charlie ${runId}`);
  
  // Everyone should now see "2 Others Guessing"
  await expect(pageA.locator('#presence-count')).toHaveText('2 Others Guessing');
  await expect(pageB.locator('#presence-count')).toHaveText('2 Others Guessing');
  await expect(pageC.locator('#presence-count')).toHaveText('2 Others Guessing');

  // --- CASE 4: The Rage Quit (Disconnect & Culling State) ---
  // We simulate Player B abruptly closing their browser window
  await pageB.close();

  // Because your main.js evaluates the presence array every 3 seconds to cull dead connections,
  // we need to tell Playwright to wait 3.5 seconds before checking the UI again.
  await pageA.waitForTimeout(3500);

  // Both remaining players should see the number drop back down to 1
  await expect(pageA.locator('#presence-count')).toHaveText('1 Other Guessing');
  await expect(pageC.locator('#presence-count')).toHaveText('1 Other Guessing');
});