(function () {
  document.addEventListener('DOMContentLoaded', function () {
    var form = document.getElementById('secretForm');
    var resultsBox = document.getElementById('resultsBox');

    form.addEventListener('submit', function (e) {
      e.preventDefault();
      generate();
    });

    // Copy button handler (delegated)
    resultsBox.addEventListener('click', function (e) {
      var btn = e.target.closest('.copy-btn');
      if (!btn) return;
      var targetId = btn.getAttribute('data-target');
      var el = document.getElementById(targetId);
      if (!el) return;
      navigator.clipboard.writeText(el.textContent).then(function () {
        btn.textContent = 'Copied!';
        setTimeout(function () { btn.textContent = 'Copy'; }, 1500);
      });
    });

    function generate() {
      var secretType = document.getElementById('secretType').value;
      var result = generators[secretType]();
      resultsBox.innerHTML = result;
      resultsBox.style.display = 'block';
      resultsBox.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
    }

    // --- Helpers ---

    function randChars(chars, len) {
      var arr = new Uint8Array(len);
      crypto.getRandomValues(arr);
      var out = '';
      for (var i = 0; i < len; i++) {
        out += chars[arr[i] % chars.length];
      }
      return out;
    }

    var ALNUM = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    var ALNUM_UPPER = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    var BASE64 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    var HEX = '0123456789abcdef';
    var BECH32 = 'qpzry9x8gf2tvdw0s3jn54khce6mua7l';

    function secretBlock(label, id, value) {
      return '<div class="secret-row">' +
        '<div class="secret-label">' + label + '</div>' +
        '<div class="secret-value-row">' +
          '<code class="secret-value" id="' + id + '">' + escapeHtml(value) + '</code>' +
          '<button type="button" class="btn btn-sm copy-btn" data-target="' + id + '">Copy</button>' +
        '</div>' +
      '</div>';
    }

    function escapeHtml(s) {
      return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
    }

    // --- Generators ---

    var generators = {
      'ghp-classic': function () {
        var token = 'ghp_' + randChars(ALNUM, 36);
        return secretBlock('GitHub Classic PAT', 'ghpToken', token);
      },

      'ghp-fine': function () {
        var token = 'github_pat_' + randChars(ALNUM, 22) + '_' + randChars(ALNUM, 59);
        return secretBlock('GitHub Fine-Grained PAT', 'ghpFineToken', token);
      },

      'aws': function () {
        var keyId = 'AKIA' + randChars(ALNUM_UPPER, 16);
        var secret = randChars(BASE64, 40);
        return secretBlock('AWS Access Key ID', 'awsKeyId', keyId) +
               secretBlock('AWS Secret Access Key', 'awsSecret', secret);
      },

      'azure-storage': function () {
        var accountName = 'stor' + randChars('abcdefghijklmnopqrstuvwxyz0123456789', 8);
        var keyBytes = randChars(BASE64, 86) + '==';
        var conn = 'DefaultEndpointsProtocol=https;AccountName=' + accountName +
          ';AccountKey=' + keyBytes + ';EndpointSuffix=core.windows.net';
        return secretBlock('Account Name', 'azureAccount', accountName) +
               secretBlock('Account Key', 'azureKey', keyBytes) +
               secretBlock('Connection String', 'azureConn', conn);
      },

      'age': function () {
        var key = 'AGE-SECRET-KEY-1' + randChars(BECH32, 42).toUpperCase();
        return secretBlock('age Secret Key', 'ageKey', key);
      },

      'generic-hex-32': function () {
        var token = randChars(HEX, 64);
        return secretBlock('256-bit Hex Secret', 'hexSecret', token);
      },

      'generic-base64-32': function () {
        var token = randChars(BASE64, 43) + '=';
        return secretBlock('256-bit Base64 Secret', 'b64Secret', token);
      },

      'slack-bot': function () {
        var token = 'xoxb-' + randChars('0123456789', 12) + '-' +
          randChars('0123456789', 13) + '-' + randChars(ALNUM, 24);
        return secretBlock('Slack Bot Token', 'slackToken', token);
      },

      'openai': function () {
        var token = 'sk-proj-' + randChars(ALNUM, 48);
        return secretBlock('OpenAI API Key', 'openaiKey', token);
      },

      'stripe-secret': function () {
        var live = 'sk_live_' + randChars(ALNUM, 48);
        var test = 'sk_test_' + randChars(ALNUM, 48);
        return secretBlock('Stripe Secret Key (Live)', 'stripeLive', live) +
               secretBlock('Stripe Secret Key (Test)', 'stripeTest', test);
      },

      'sendgrid': function () {
        var token = 'SG.' + randChars(ALNUM + '-_', 22) + '.' + randChars(ALNUM + '-_', 43);
        return secretBlock('SendGrid API Key', 'sendgridKey', token);
      },

      'gcp-service': function () {
        var projectId = 'project-' + randChars('abcdefghijklmnopqrstuvwxyz0123456789', 6);
        var clientEmail = 'svc-' + randChars('abcdefghijklmnopqrstuvwxyz', 8) + '@' + projectId + '.iam.gserviceaccount.com';
        var privateKeyId = randChars(HEX, 40);
        var fakeKeyBody = randChars(BASE64, 300);
        var json = JSON.stringify({
          type: 'service_account',
          project_id: projectId,
          private_key_id: privateKeyId,
          private_key: '-----BEGIN RSA PRIVATE KEY-----\\n' + fakeKeyBody + '\\n-----END RSA PRIVATE KEY-----\\n',
          client_email: clientEmail,
          client_id: randChars('0123456789', 21),
          auth_uri: 'https://accounts.google.com/o/oauth2/auth',
          token_uri: 'https://oauth2.googleapis.com/token'
        }, null, 2);
        return secretBlock('Client Email', 'gcpEmail', clientEmail) +
               secretBlock('Private Key ID', 'gcpKeyId', privateKeyId) +
               '<div class="secret-row">' +
                 '<div class="secret-label">Service Account JSON</div>' +
                 '<div class="secret-value-row">' +
                   '<pre class="secret-value secret-json" id="gcpJson">' + escapeHtml(json) + '</pre>' +
                   '<button type="button" class="btn btn-sm copy-btn" data-target="gcpJson">Copy</button>' +
                 '</div>' +
               '</div>';
      }
    };
  });
})();
