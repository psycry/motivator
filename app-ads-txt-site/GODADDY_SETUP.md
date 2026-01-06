# GoDaddy DNS Setup Guide

## Quick Steps

### 1. Deploy to Netlify
- Drag `app-ads-txt-site` folder to https://app.netlify.com
- Get your Netlify URL (e.g., `magical-unicorn-123456.netlify.app`)

### 2. GoDaddy DNS Configuration

#### Access DNS Settings
1. Log into GoDaddy: https://dcc.godaddy.com/
2. Click **"My Products"**
3. Find **digitalnomad.sh**
4. Click **"DNS"** button (or three dots → Manage DNS)

#### Add CNAME Record
1. Scroll to **"Records"** section
2. Click **"Add"** button
3. Fill in:

```
┌──────────────────────────────────────────┐
│ Type:  CNAME                             │
│ Name:  www                               │
│ Value: your-site-name.netlify.app        │
│ TTL:   1 Hour                            │
└──────────────────────────────────────────┘
```

4. Click **"Save"**

### 3. Configure Netlify Custom Domain

1. In Netlify: **Site Settings** → **Domain Management**
2. Click **"Add custom domain"**
3. Enter: `www.digitalnomad.sh`
4. Click **"Verify"** and **"Add domain"**
5. Wait 1-5 minutes for HTTPS certificate

### 4. Test
- Wait 5-30 minutes for DNS propagation
- Visit: `https://www.digitalnomad.sh/app-ads.txt`
- Should display your app-ads.txt content

## Troubleshooting

### "CNAME record already exists"

**Solution 1: Delete existing www record**
1. Find the existing `www` record in GoDaddy DNS
2. Click the pencil/edit icon
3. Click **"Delete"**
4. Add the new CNAME to Netlify

**Solution 2: Use different subdomain**
Instead of `www`, use:
- `ads.digitalnomad.sh`
- `app.digitalnomad.sh`
- `api.digitalnomad.sh`

Just change the "Name" field to `ads` (or whatever you choose)

### "Forwarding conflicts" warning

This is normal! Your root domain forwarding will continue to work. The `www` subdomain is separate.

### DNS not propagating

**Check DNS:**
```bash
nslookup www.digitalnomad.sh
```

Should show:
```
www.digitalnomad.sh    canonical name = your-site.netlify.app
```

**If not working:**
- Wait longer (can take up to 48 hours, usually 5-30 minutes)
- Clear your DNS cache: `ipconfig /flushdns` (Windows)
- Try from a different network/device
- Check GoDaddy DNS settings are saved correctly

### HTTPS certificate not provisioning

**In Netlify:**
1. Go to **Domain Management**
2. Check if domain shows "Awaiting External DNS"
3. Click **"Verify DNS configuration"**
4. If DNS is correct, certificate will provision in 1-5 minutes

**If still failing:**
- Ensure CNAME points to Netlify (not an IP address)
- Remove any CAA records in GoDaddy that might block Let's Encrypt
- Contact Netlify support if issue persists

## GoDaddy DNS Records Reference

### What Your DNS Should Look Like

```
Type    │ Name │ Value                      │ TTL  │ Notes
────────┼──────┼────────────────────────────┼──────┼─────────────────
A       │ @    │ 192.0.2.1                  │ 1hr  │ Your existing root domain
CNAME   │ www  │ your-site.netlify.app      │ 1hr  │ NEW - Add this
```

### What NOT to Do

❌ **Don't add:**
```
Type    │ Name │ Value
────────┼──────┼────────────────────────────
A       │ www  │ 75.2.60.5  ← Wrong! Use CNAME, not A record
```

❌ **Don't include protocol:**
```
Value: https://your-site.netlify.app  ← Wrong!
Value: your-site.netlify.app          ← Correct!
```

❌ **Don't add trailing dot:**
```
Value: your-site.netlify.app.  ← Wrong!
Value: your-site.netlify.app   ← Correct!
```

## Alternative Subdomain Setup

If you want to use a different subdomain:

### Using "ads" subdomain

**GoDaddy:**
```
Type:  CNAME
Name:  ads
Value: your-site.netlify.app
```

**Netlify:**
- Add custom domain: `ads.digitalnomad.sh`

**Result:**
- Your app-ads.txt at: `https://ads.digitalnomad.sh/app-ads.txt`

### Using "app" subdomain

**GoDaddy:**
```
Type:  CNAME
Name:  app
Value: your-site.netlify.app
```

**Netlify:**
- Add custom domain: `app.digitalnomad.sh`

**Result:**
- Your app-ads.txt at: `https://app.digitalnomad.sh/app-ads.txt`

## Important Notes

✅ **Your main domain forwarding stays intact**
- `digitalnomad.sh` continues to forward/mask to GitHub Pages
- Only the subdomain (`www.digitalnomad.sh`) uses proper DNS

✅ **Free HTTPS included**
- Netlify automatically provisions Let's Encrypt certificates
- No additional configuration needed

✅ **Global CDN**
- Your app-ads.txt served from Netlify's global CDN
- Fast access from anywhere in the world

✅ **Easy updates**
- Just update the file in Netlify dashboard
- Or redeploy the folder
- Changes are instant

## Support

**GoDaddy DNS Help:**
- https://www.godaddy.com/help/add-a-cname-record-19236

**Netlify Custom Domain Help:**
- https://docs.netlify.com/domains-https/custom-domains/

**Need Help?**
- GoDaddy Support: 480-505-8877
- Netlify Support: https://answers.netlify.com/
