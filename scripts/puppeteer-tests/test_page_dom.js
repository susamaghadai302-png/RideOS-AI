const puppeteer = require('puppeteer-core');

(async () => {
  const browser = await puppeteer.launch({
    executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    headless: 'new',
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--enable-webgl', '--use-gl=angle', '--use-angle=metal', '--window-size=1280,950']
  });

  const page = await browser.newPage();
  await page.setViewport({ width: 1280, height: 950 });

  page.on('console', msg => console.log('[Browser Console]', msg.type(), msg.text()));
  page.on('pageerror', err => console.error('[Browser Error]', err));

  console.log('Opening http://localhost:8080...');
  await page.goto('http://localhost:8080', { waitUntil: 'networkidle0', timeout: 30000 });
  await new Promise(r => setTimeout(r, 6000));

  const bodyHtml = await page.evaluate(() => document.body.innerHTML);
  console.log('Body HTML length:', bodyHtml.length);
  console.log('Body HTML sample:', bodyHtml.slice(0, 500));

  await page.screenshot({ path: '/Users/hitanshughadai/.gemini/antigravity-ide/brain/f606ec9c-b106-46fc-9d6e-e5278b727ddf/page_initial.png' });
  console.log('Saved page_initial.png');

  await browser.close();
})();
