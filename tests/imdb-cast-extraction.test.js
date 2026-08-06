// @ts-check
const { test, expect } = require('@playwright/test');

const TEST_URL = 'https://www.imdb.com/title/tt2709768/fullcredits/';

// Mirrors the bookmarklet extraction logic exactly.
// Returns { actors, strategy } so tests can assert which strategy fired.
async function extractCast(page) {
  return page.evaluate(() => {
    const actors = [];
    const seen = new Set();
    let strategy = null;

    function charText(el) {
      return el ? el.textContent.replace(/\s+/g, ' ').replace(/\(uncredited\)/gi, '').trim() : '';
    }

    function add(link, ch) {
      const href = link.getAttribute('href') || '';
      const nm = href.match(/nm\d+/);
      if (!nm || seen.has(nm[0])) return;
      const n = link.textContent.trim();
      if (!n) return;
      seen.add(nm[0]);
      actors.push({ name: n, nconst: nm[0], character: ch || '' });
    }

    // S1: classic cast_list with itemprop="actor"
    document.querySelectorAll('table.cast_list tr').forEach(row => {
      const cell = row.querySelector('td[itemprop="actor"]');
      if (!cell) return;
      const link = cell.querySelector('a[href*="/name/nm"]');
      if (!link) return;
      add(link, charText(row.querySelector('td.character')));
    });
    if (actors.length) { strategy = 'S1:cast_list+itemprop'; }

    // S2: cast_list table, itemprop stripped
    if (!actors.length) {
      document.querySelectorAll('table.cast_list tr').forEach(row => {
        const link = row.querySelector('a[href*="/name/nm"]');
        if (!link) return;
        const tds = row.querySelectorAll('td');
        add(link, tds.length >= 3 ? charText(tds[tds.length - 1]) : '');
      });
      if (actors.length) strategy = 'S2:cast_list+anylink';
    }

    // S3: densest table of /name/ links
    if (!actors.length) {
      let best = null, max = 0;
      document.querySelectorAll('table').forEach(t => {
        const c = t.querySelectorAll('a[href*="/name/nm"]').length;
        if (c > max) { max = c; best = t; }
      });
      if (best && max > 2) {
        best.querySelectorAll('tr').forEach(row => {
          const link = row.querySelector('a[href*="/name/nm"]');
          if (!link) return;
          const tds = row.querySelectorAll('td');
          add(link, tds.length >= 3 ? charText(tds[tds.length - 1]) : '');
        });
        if (actors.length) strategy = `S3:densest-table(${max}links)`;
      }
    }

    // S4: new React title page cast cards
    if (!actors.length) {
      document.querySelectorAll('[data-testid="title-cast-item"]').forEach(item => {
        const link = item.querySelector('a[href*="/name/nm"]');
        if (!link) return;
        add(link, charText(item.querySelector('[data-testid="cast-item-characters-link"]')));
      });
      if (actors.length) strategy = 'S4:data-testid=title-cast-item';
    }

    // S4b: IMDB fullcredits 2024+ — cast section testid contains "name_credit_group"
    if (!actors.length) {
      let castSection = document.querySelector('[data-testid*="name_credit_group"]');
      if (!castSection) {
        Array.from(document.querySelectorAll('[data-testid^="sub-section-"]')).some(sec => {
          const prev = sec.previousElementSibling;
          if (prev && /\bcast\b/i.test(prev.textContent)) { castSection = sec; return true; }
        });
      }
      if (castSection) {
        castSection.querySelectorAll('[data-testid="name-credits-list-item"]').forEach(item => {
          const link = item.querySelector('a.name-credits--title-text-big');
          if (!link) return;
          const charLink = item.querySelector('a[href*="/characters/"]');
          let ch = '';
          if (charLink) {
            ch = charLink.textContent.trim();
            const paren = charLink.parentElement?.nextElementSibling;
            if (paren) ch += ' ' + paren.textContent.trim();
            ch = ch.replace(/\s+/g, ' ').trim();
          }
          add(link, ch);
        });
        if (actors.length) strategy = 'S4b:name_credit_group';
      }
    }

    // S5: find "Cast" heading, walk up until a container has 3+ links
    if (!actors.length) {
      const headings = Array.from(document.querySelectorAll('h3,h4,h5,span,div,li')).filter(el =>
        el.children.length === 0 && /^cast$/i.test(el.textContent.trim())
      );
      headings.forEach(h => {
        let container = h.parentElement;
        for (let i = 0; i < 5; i++) {
          if (!container) break;
          const links = container.querySelectorAll('a[href*="/name/nm"]');
          if (links.length > 2) {
            links.forEach(link => add(link, ''));
            return;
          }
          container = container.parentElement;
        }
      });
      if (actors.length) strategy = 'S5:cast-heading';
    }

    // S6: all /name/ links on page (last resort)
    if (!actors.length) {
      document.querySelectorAll('a[href*="/name/nm"]').forEach(link => add(link, ''));
      if (actors.length) strategy = 'S6:all-name-links';
    }

    // Diagnostic snapshot if nothing worked
    const diagnostics = {
      tables: document.querySelectorAll('table').length,
      lists: document.querySelectorAll('ul,ol').length,
      totalNameLinks: document.querySelectorAll('a[href*="/name/nm"]').length,
      sampleTestIds: Array.from(document.querySelectorAll('[data-testid]'))
        .slice(0, 8).map(e => e.getAttribute('data-testid')),
      sampleClasses: Array.from(document.querySelectorAll('[class]'))
        .map(e => e.className).filter(c => /cast|credit|crew/i.test(c)).slice(0, 8),
    };

    return { actors, strategy, diagnostics };
  });
}

test.describe('IMDB cast extraction — tt2709768', () => {
  let result;

  test.beforeAll(async ({ browser }) => {
    const page = await browser.newPage();
    // Accept cookies / age gates if present
    await page.goto(TEST_URL, { waitUntil: 'domcontentloaded' });
    // Give any JS-rendered content a moment to settle
    await page.waitForTimeout(1500);
    result = await extractCast(page);
    await page.close();
    console.log('\n--- extraction result ---');
    console.log('strategy:', result.strategy);
    console.log('actor count:', result.actors.length);
    console.log('first 5:', result.actors.slice(0, 5).map(a => `${a.name} (${a.nconst}) as "${a.character}"`));
    console.log('diagnostics:', JSON.stringify(result.diagnostics, null, 2));
  });

  test('finds at least one actor', () => {
    expect(result.actors.length).toBeGreaterThan(0);
  });

  test('every actor has a non-empty name', () => {
    result.actors.forEach(a => {
      expect(a.name.trim().length).toBeGreaterThan(0);
    });
  });

  test('every actor has a valid nconst (nm\\d+)', () => {
    result.actors.forEach(a => {
      expect(a.nconst).toMatch(/^nm\d+$/);
    });
  });

  test('nconst values are unique (no duplicates)', () => {
    const nconsts = result.actors.map(a => a.nconst);
    expect(new Set(nconsts).size).toBe(nconsts.length);
  });

  test('a strategy resolved (not null)', () => {
    expect(result.strategy).not.toBeNull();
  });

  test('at least some actors have character names (when strategy supports it)', () => {
    const withChar = result.actors.filter(a => a.character.length > 0);
    const characterExtractingStrategies = ['S1:cast_list+itemprop', 'S2:cast_list+anylink', 'S3:densest-table', 'S4:data-testid=title-cast-item', 'S4b:name_credit_group'];
    if (characterExtractingStrategies.includes(result.strategy)) {
      // These strategies know how to find character text — expect >50% coverage
      expect(withChar.length).toBeGreaterThan(result.actors.length * 0.5);
    } else {
      // S5/S6 are fallbacks that don't extract characters
      console.log(`  note: strategy ${result.strategy} does not extract character names (${withChar.length}/${result.actors.length} found)`);
    }
  });
});
