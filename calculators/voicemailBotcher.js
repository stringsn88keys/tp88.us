(function () {
  document.addEventListener('DOMContentLoaded', function () {
    var form = document.getElementById('vmForm');
    var input = document.getElementById('vmInput');
    var intensityInputs = document.querySelectorAll('input[name="intensity"]');
    var resultBox = document.getElementById('resultBox');
    var rebotchBtn = document.getElementById('rebotchBtn');
    var copyBtn = document.getElementById('copyBtn');
    var exampleBtn = document.getElementById('exampleBtn');

    var lastPlainText = '';

    form.addEventListener('submit', function (e) {
      e.preventDefault();
      run();
    });

    rebotchBtn.addEventListener('click', function () {
      if (input.value.trim()) run();
    });

    exampleBtn.addEventListener('click', function () {
      input.value = EXAMPLES[Math.floor(Math.random() * EXAMPLES.length)];
      run();
    });

    copyBtn.addEventListener('click', function () {
      if (!lastPlainText) return;
      navigator.clipboard.writeText(lastPlainText).then(function () {
        copyBtn.textContent = 'Copied!';
        setTimeout(function () { copyBtn.textContent = 'Copy Transcription'; }, 1500);
      });
    });

    function currentIntensity() {
      for (var i = 0; i < intensityInputs.length; i++) {
        if (intensityInputs[i].checked) return intensityInputs[i].value;
      }
      return 'classic';
    }

    function run() {
      var text = input.value.trim();
      if (!text) return;
      var result = botch(text, currentIntensity());
      lastPlainText = result.plain;
      render(result);
    }

    function render(result) {
      var now = new Date();
      var timeStr = now.toLocaleTimeString([], { hour: 'numeric', minute: '2-digit' });
      var duration = (Math.floor(Math.random() * 3) + 0) + ':' + String(Math.floor(Math.random() * 50) + 5).padStart(2, '0');

      resultBox.innerHTML =
        '<div class="vm-card">' +
          '<div class="vm-header">' +
            '<div class="vm-avatar">📞</div>' +
            '<div class="vm-meta">' +
              '<div class="vm-caller">Unknown Caller</div>' +
              '<div class="vm-sub">Voicemail &middot; ' + duration + ' &middot; Today ' + timeStr + '</div>' +
            '</div>' +
            '<div class="vm-dot" title="New"></div>' +
          '</div>' +
          '<div class="vm-waveform">' + waveformBars() + '</div>' +
          '<div class="vm-transcript-label">Transcription <span class="vm-beta">Beta</span></div>' +
          '<div class="vm-transcript">' + result.html + '</div>' +
          '<div class="vm-disclaimer">Confidence in gray. Accuracy is, uh, aspirational.</div>' +
        '</div>';
      resultBox.style.display = 'block';
      copyBtn.style.display = 'inline-block';
      resultBox.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
    }

    function waveformBars() {
      var out = '';
      var n = 40;
      for (var i = 0; i < n; i++) {
        var h = 20 + Math.floor(Math.random() * 80);
        out += '<span style="height:' + h + '%"></span>';
      }
      return out;
    }

    // --- Botching engine ---

    // Plausible near-miss mishears: common voicemail vocabulary mapped to
    // words that sound (vaguely) similar or are frequent homophone traps.
    var NEAR_MISS = {
      hi: ['hi', 'high', 'hey'],
      hey: ['hey', 'hay'],
      hello: ['hello', 'yellow', 'hell oh'],
      call: ['call', 'caul', 'col'],
      calling: ['calling', 'calming', 'crawling'],
      called: ['called', 'cold', 'cauld'],
      back: ['back', 'bac', 'bak'],
      later: ['later', 'ladder', 'lay dur'],
      today: ['today', 'to day', 'to date'],
      tomorrow: ['tomorrow', 'to Marrow', 'tomato row'],
      tonight: ['tonight', 'to night', 'the night'],
      morning: ['morning', 'mourning'],
      meeting: ['meeting', 'meating', 'meting'],
      meet: ['meet', 'meat', 'mete'],
      time: ['time', 'thyme', 'tine'],
      phone: ['phone', 'foam', 'fone'],
      number: ['number', 'numb er', 'lumber'],
      message: ['message', 'massage', 'mess edge'],
      voicemail: ['voicemail', 'boys mail', 'voice male'],
      please: ['please', 'peas', 'pleas'],
      thanks: ['thanks', 'tanks', 'thinks'],
      thank: ['thank', 'thang'],
      you: ['you', 'ewe', 'yew'],
      your: ['your', "you're", 'ur'],
      "you're": ['your', "you're", 'ewer'],
      going: ['going', 'goin', 'gowing'],
      home: ['home', 'holm', 'hone'],
      work: ['work', 'werk', 'wok'],
      office: ['office', 'awful fist'],
      sorry: ['sorry', 'sari', 'saury'],
      missed: ['missed', 'mist', 'mixed'],
      busy: ['busy', 'bizzy', 'bussy'],
      free: ['free', 'flee', 'thee'],
      lunch: ['lunch', 'launch', 'lunge'],
      dinner: ['dinner', 'diner', 'din er'],
      coffee: ['coffee', 'copy', 'khaki'],
      minutes: ['minutes', 'minuets', 'my nuts'],
      hour: ['hour', 'our', 'are'],
      hours: ['hours', 'ours', 'ares'],
      address: ['address', 'a dress', 'ad rest'],
      email: ['email', 'E male', 'ee mail'],
      send: ['send', 'cent', 'scent'],
      text: ['text', 'tekst', 'taxed'],
      reply: ['reply', 're ply', 'ripply'],
      need: ['need', 'knead', 'ned'],
      want: ['want', "won't", 'wont'],
      know: ['know', 'no', 'gnaw'],
      think: ['think', 'thing', 'thin'],
      sure: ['sure', 'shore', 'sher'],
      right: ['right', 'write', 'rite'],
      okay: ['okay', 'okie', 'O K'],
      yes: ['yes', 'yesh', 'yez'],
      no: ['no', 'know', 'noh'],
      maybe: ['maybe', 'may be', 'may bee'],
      soon: ['soon', 'sune', 'swoon'],
      still: ['still', 'steel', 'stil'],
      just: ['just', 'jest', 'joust'],
      really: ['really', 'reelly', 'rilly'],
      actually: ['actually', 'ax shully'],
      important: ['important', 'impotent', 'impart ant'],
      urgent: ['urgent', 'ur gent', 'er gent'],
      question: ['question', 'quest chin'],
      answer: ['answer', 'an sir', 'anther'],
      help: ['help', 'yelp', 'kelp'],
      project: ['project', 'pro ject', 'progect'],
      deadline: ['deadline', 'dead line', 'dead lime'],
      schedule: ['schedule', 'shed jewel'],
      appointment: ['appointment', 'a pointment', 'a point mint'],
      doctor: ['doctor', 'dock tor'],
      car: ['car', 'care', 'cur'],
      house: ['house', 'hows', 'howse'],
      dog: ['dog', 'dawg', 'dock'],
      cat: ['cat', 'kat', 'catt'],
      kids: ['kids', 'kits', 'kidz'],
      family: ['family', 'fam uh lee'],
      weekend: ['weekend', 'week end', 'weakened'],
      week: ['week', 'weak', 'weke'],
      month: ['month', 'munth'],
      year: ['year', 'ear', 'yeer'],
      money: ['money', 'mony', 'muny'],
      pay: ['pay', 'pey', 'pei'],
      bill: ['bill', 'bil', 'bhil'],
      order: ['order', 'oder', 'aughter'],
      package: ['package', 'pack age', 'packedge'],
      delivery: ['delivery', 'deliver E'],
      store: ['store', 'stor', 'stoar'],
      weather: ['weather', 'whether', 'wether'],
      traffic: ['traffic', 'trafic', 'tra fick'],
      drive: ['drive', 'derive', 'dr ive'],
      walking: ['walking', 'wok king', 'walk ing'],
      running: ['running', 'run ing', 'rooning'],
      stop: ['stop', 'stahp', 'staph'],
      start: ['start', 'stort', 'startt'],
      finish: ['finish', 'finnish', 'fin ish'],
      done: ['done', 'dun', 'dawn'],
      ready: ['ready', 'reddy', 'red E'],
      wait: ['wait', 'weight', 'wate'],
      hold: ['hold', 'holed', 'holt'],
      line: ['line', 'lyin', 'lign'],
      leave: ['leave', 'lieve', 'leev'],
      mailbox: ['mailbox', 'male box'],
      contract: ['contract', 'con tract', 'con track'],
      insurance: ['insurance', 'in shorance'],
      account: ['account', 'a count', 'uh count'],
      password: ['password', 'pass word', 'past word'],
      wifi: ['wifi', 'why fi', 'wife eye'],
      flight: ['flight', 'flite'],
      airport: ['airport', 'air port'],
      hotel: ['hotel', 'ho tell', 'oh tell'],
      dentist: ['dentist', 'den tist'],
      birthday: ['birthday', 'burped A'],
      party: ['party', 'par tea'],
      game: ['game', 'gaym'],
      team: ['team', 'teem'],
      boss: ['boss', 'bos', 'baws'],
      client: ['client', 'cly ent'],
      it: ['it', 'eat'],
      is: ['is', 'iz'],
      the: ['the', 'thee', 'duh']
    };

    // Wilder, non-sequitur mishears used more heavily at Chaos intensity.
    var CHAOS_ABSURD = {
      call: ['cauliflower', 'calzone', 'Kowalski'],
      back: ['bat', 'bacon', 'Baghdad'],
      meeting: ['manatee', 'meat cleaver', 'my knee'],
      voicemail: ['royal whale', 'boil kale'],
      tomorrow: ['tomato row', 'to Moscow'],
      number: ['cucumber', 'lumberjack'],
      message: ['massage parlor', 'mess of eggs'],
      time: ['thyme leaf', 'time zone banana'],
      phone: ['pony', 'phone booth ghost'],
      hi: ['hive', 'Hawaii'],
      dinner: ['dinosaur', 'diner waffle'],
      office: ['orphanage', 'awkward fish'],
      important: ['impotent walrus', 'important-ish'],
      question: ['quest for chin'],
      appointment: ['a pointy mint'],
      insurance: ['in a trance', 'insurgents'],
      family: ['fam of bees'],
      weekend: ['weak end table'],
      project: ['pro jester']
    };

    // Endings Apple's engine seems to invent out of thin air when the
    // audio trails off. Purely fictional, purely for comedic effect.
    var HALLUCINATED_TAILS = [
      'and that concludes the weather portion of our broadcast',
      'subscribe to my newsletter for more updates',
      'this has been a message from the void',
      'please rate this call five stars',
      'the cake is a metaphor',
      'and remember folks, always check your tire pressure',
      'thank you for calling the sandwich hotline',
      'that\'s all from mission control',
      'in conclusion, bananas',
      'and scene'
    ];

    var CUTOFF_NOTES = [
      '[Confidence too low to continue]',
      '[Signal lost]',
      '[Caller may be underwater]',
      '[Audio quality: questionable]'
    ];

    var EXAMPLES = [
      "Hey it's me, just wanted to check if we're still on for the meeting tomorrow at noon, call me back when you get a chance.",
      "Hi, this is Doctor Patel's office calling to confirm your appointment on Thursday at 2:30, please call us back to confirm.",
      "Hey it's your brother, I'm gonna be a little late tonight, traffic is insane, can you grab the package from the front office?",
      "Hi, I'm calling about the invoice for the project, I think there might be a mistake on the number, give me a call back when you're free.",
      "Hey it's me again, sorry I missed your call earlier, I was in the car, let's grab coffee this weekend if you're free.",
      "This is a reminder that your flight tomorrow morning has been delayed, please check your email for the updated itinerary."
    ];

    function pick(arr) {
      return arr[Math.floor(Math.random() * arr.length)];
    }

    function matchCase(sample, replacement) {
      if (sample === sample.toUpperCase() && sample !== sample.toLowerCase()) {
        return replacement.toUpperCase();
      }
      if (sample[0] === sample[0].toUpperCase()) {
        return replacement.charAt(0).toUpperCase() + replacement.slice(1);
      }
      return replacement;
    }

    // Generic phonetic-ish scrambler for words with no dictionary entry.
    function scramble(word) {
      if (word.length < 4) return word;
      var chars = word.split('');
      var vowels = 'aeiouAEIOU';
      var vowelIdx = [];
      for (var i = 0; i < chars.length; i++) {
        if (vowels.indexOf(chars[i]) !== -1) vowelIdx.push(i);
      }
      var move = Math.random();
      if (vowelIdx.length && move < 0.5) {
        var idx = pick(vowelIdx);
        var pool = 'aeiou';
        chars[idx] = pick(pool.split(''));
      } else if (chars.length >= 5 && move < 0.8) {
        var a = 1 + Math.floor(Math.random() * (chars.length - 2));
        var b = a + 1;
        var tmp = chars[a];
        chars[a] = chars[b];
        chars[b] = tmp;
      } else {
        chars.splice(chars.length - 2, 1);
      }
      return chars.join('');
    }

    var INTENSITY = {
      mild: { botchChance: 0.14, absurdChance: 0.0, tailChance: 0.0, cutoffChance: 0.0, strayGrayChance: 0.03 },
      classic: { botchChance: 0.3, absurdChance: 0.15, tailChance: 0.15, cutoffChance: 0.1, strayGrayChance: 0.08 },
      chaos: { botchChance: 0.55, absurdChance: 0.4, tailChance: 0.55, cutoffChance: 0.35, strayGrayChance: 0.18 }
    };

    function botch(text, intensity) {
      var cfg = INTENSITY[intensity] || INTENSITY.classic;

      // Apple-style flattening: strip most punctuation, run it together.
      var stripped = text.replace(/[.,;:!?]+/g, ' ').replace(/\s+/g, ' ').trim();

      var tokens = stripped.match(/[A-Za-z']+|[^A-Za-z']+/g) || [];
      var htmlParts = [];
      var plainParts = [];

      var wordCount = 0;
      var totalWords = tokens.filter(function (t) { return /[A-Za-z]/.test(t); }).length;
      var cutoffAt = cfg.cutoffChance > 0 && Math.random() < cfg.cutoffChance
        ? Math.max(3, Math.floor(totalWords * (0.35 + Math.random() * 0.35)))
        : -1;

      var stopped = false;

      for (var i = 0; i < tokens.length; i++) {
        var tok = tokens[i];
        if (!/[A-Za-z]/.test(tok)) {
          htmlParts.push(escapeHtml(tok));
          plainParts.push(tok);
          continue;
        }

        wordCount++;
        if (cutoffAt !== -1 && wordCount > cutoffAt) {
          stopped = true;
          break;
        }

        var lower = tok.toLowerCase();
        var out = tok;
        var botched = false;

        var useAbsurd = CHAOS_ABSURD[lower] && Math.random() < cfg.absurdChance;
        if (useAbsurd) {
          out = matchCase(tok, pick(CHAOS_ABSURD[lower]));
          botched = true;
        } else if (NEAR_MISS[lower] && Math.random() < cfg.botchChance) {
          var options = NEAR_MISS[lower].filter(function (w) { return w !== lower; });
          if (options.length) {
            out = matchCase(tok, pick(options));
            botched = true;
          }
        } else if (!NEAR_MISS[lower] && Math.random() < cfg.botchChance * 0.6) {
          var scrambled = scramble(lower);
          if (scrambled !== lower) {
            out = matchCase(tok, scrambled);
            botched = true;
          }
        }

        var strayGray = !botched && Math.random() < cfg.strayGrayChance;

        if (botched || strayGray) {
          htmlParts.push('<span class="vm-low-conf">' + escapeHtml(out) + '</span>');
        } else {
          htmlParts.push(escapeHtml(out));
        }
        plainParts.push(out);
      }

      var html = htmlParts.join('');
      var plain = plainParts.join('');

      if (stopped) {
        var note = pick(CUTOFF_NOTES);
        html += ' <span class="vm-low-conf vm-italic">&hellip; ' + escapeHtml(note) + '</span>';
        plain += ' ... ' + note;
      } else if (cfg.tailChance > 0 && Math.random() < cfg.tailChance) {
        var tail = pick(HALLUCINATED_TAILS);
        html += ' <span class="vm-low-conf vm-italic">' + escapeHtml(tail) + '</span>';
        plain += ' ' + tail;
      }

      // Apple-ism: sentence case only at the very start.
      html = capitalizeFirstVisible(html);
      plain = plain.charAt(0).toUpperCase() + plain.slice(1);

      return { html: html, plain: plain };
    }

    function capitalizeFirstVisible(html) {
      return html.replace(/(<[^>]*>)*([a-zA-Z])/, function (match, tag, letter) {
        return match.slice(0, match.length - 1) + letter.toUpperCase();
      });
    }

    function escapeHtml(s) {
      return s
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;');
    }
  });
})();
