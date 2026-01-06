# App-ads.txt Hosting Site

This is a simple static site to host your `app-ads.txt` file for the digitalnomad.sh domain.

## Files

- **app-ads.txt** - Your app-ads.txt file (UPDATE WITH YOUR PUBLISHER ID)
- **index.html** - Homepage that redirects to main site
- **netlify.toml** - Netlify configuration
- **README.md** - This file

## Deployment Instructions

### Option A: Netlify Drag & Drop (Easiest)

1. **Update app-ads.txt** with your actual publisher ID
2. Go to https://app.netlify.com
3. Sign in/Sign up
4. Drag the entire `app-ads-txt-site` folder onto the Netlify dashboard
5. Your site will be deployed with a URL like: `your-site-name.netlify.app`

### Option B: Netlify CLI

```bash
# Install Netlify CLI (one time)
npm install -g netlify-cli

# Navigate to this folder
cd app-ads-txt-site

# Login to Netlify
netlify login

# Deploy
netlify deploy --prod
```

### Option C: GitHub + Netlify Auto-Deploy

1. Create a new GitHub repository
2. Push this folder to the repository
3. In Netlify, click "New site from Git"
4. Connect your GitHub repository
5. Netlify will auto-deploy on every push

## DNS Configuration

After deployment, configure your DNS:

### At Your Domain Registrar (digitalnomad.sh)

Add a CNAME record:

```
Type: CNAME
Name: www (or ads, or any subdomain)
Value: your-site-name.netlify.app
TTL: 3600
```

### In Netlify

1. Go to Site Settings → Domain Management
2. Click "Add custom domain"
3. Enter: `www.digitalnomad.sh` (or your chosen subdomain)
4. Netlify will verify DNS and enable HTTPS automatically

## Verification

After DNS propagates (5-60 minutes), verify:

1. Visit: `https://www.digitalnomad.sh/app-ads.txt`
2. You should see your app-ads.txt content
3. Use Google's validator: https://adstxt.guru/

## Update Your Ad Network

In your ad network settings (Google AdMob, etc.), update the app-ads.txt URL to:

```
https://www.digitalnomad.sh/app-ads.txt
```

## Important Notes

- **Update app-ads.txt** with your actual publisher ID before deploying
- Keep your main site (digitalnomad.sh) as-is with domain masking
- Only the subdomain (www.digitalnomad.sh) needs proper DNS
- HTTPS is automatically provided by Netlify
- The site will redirect visitors to your main domain while serving app-ads.txt correctly

## Troubleshooting

**DNS not working?**
- Wait 5-60 minutes for DNS propagation
- Use `nslookup www.digitalnomad.sh` to check DNS
- Verify CNAME record is correct

**app-ads.txt not found?**
- Check file is named exactly `app-ads.txt` (no .txt.txt)
- Verify deployment was successful in Netlify
- Check Netlify logs for errors

**HTTPS certificate issues?**
- Netlify auto-provisions Let's Encrypt certificates
- This can take a few minutes after DNS verification
- Check Site Settings → Domain Management in Netlify
