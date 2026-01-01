# 🚀 Deployment Checklist

Use this checklist to deploy the admin dashboard to production.

## Pre-Deployment

### ✅ Firebase Setup
- [ ] Firebase project created
- [ ] Firestore database enabled
- [ ] Firebase Authentication enabled
- [ ] Firebase Storage enabled
- [ ] Firebase hosting enabled (optional)

### ✅ Security Rules
- [ ] Firestore security rules configured
- [ ] Storage security rules configured
- [ ] Authentication rules configured
- [ ] API keys restricted (optional)

### ✅ Environment Configuration
- [ ] Production `.env` file created
- [ ] Firebase credentials added
- [ ] Service account key downloaded
- [ ] `.env` added to `.gitignore`
- [ ] `firebase-service-account.json` added to `.gitignore`

### ✅ Admin Users
- [ ] At least one super admin created
- [ ] Admin users documented
- [ ] Passwords stored securely

## Build & Test

### ✅ Development Testing
- [ ] All features tested locally
- [ ] Authentication working
- [ ] CRUD operations working
- [ ] File uploads working
- [ ] Real-time updates working
- [ ] No console errors

### ✅ Production Build
```bash
npm run build
```
- [ ] Build completes without errors
- [ ] No TypeScript errors
- [ ] No linting errors
- [ ] Bundle size acceptable

### ✅ Preview Build
```bash
npm run preview
```
- [ ] Preview works correctly
- [ ] All routes accessible
- [ ] Assets loading correctly

## Deployment Options

### Option 1: Firebase Hosting

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize hosting
firebase init hosting

# Deploy
firebase deploy --only hosting
```

**Configuration** (`firebase.json`):
```json
{
  "hosting": {
    "public": "dist",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ]
  }
}
```

### Option 2: Vercel

```bash
# Install Vercel CLI
npm install -g vercel

# Deploy
vercel
```

### Option 3: Netlify

```bash
# Install Netlify CLI
npm install -g netlify-cli

# Deploy
netlify deploy --prod --dir=dist
```

### Option 4: Custom Server

1. Build the project:
```bash
npm run build
```

2. Copy `dist` folder to your server

3. Configure web server (Nginx example):
```nginx
server {
    listen 80;
    server_name your-domain.com;
    root /path/to/dist;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

## Post-Deployment

### ✅ Verification
- [ ] Site accessible at production URL
- [ ] Login working
- [ ] All features working
- [ ] No console errors
- [ ] Mobile responsive
- [ ] Performance acceptable

### ✅ Security
- [ ] HTTPS enabled
- [ ] Firebase rules tested
- [ ] Admin access restricted
- [ ] Service account key secure
- [ ] Environment variables secure

### ✅ Monitoring
- [ ] Firebase Analytics enabled (optional)
- [ ] Error tracking setup (optional)
- [ ] Performance monitoring (optional)
- [ ] Usage monitoring

### ✅ Documentation
- [ ] Admin credentials documented
- [ ] Deployment process documented
- [ ] Backup procedures documented
- [ ] Support contacts documented

## Maintenance

### Regular Tasks
- [ ] Monitor Firebase usage
- [ ] Check for security updates
- [ ] Review user access
- [ ] Backup Firestore data
- [ ] Update dependencies

### Monthly Tasks
- [ ] Review analytics
- [ ] Check error logs
- [ ] Update documentation
- [ ] Test backup restore

### Quarterly Tasks
- [ ] Security audit
- [ ] Performance review
- [ ] User feedback review
- [ ] Feature planning

## Troubleshooting

### Build Fails
- Check Node.js version (v18+)
- Clear node_modules and reinstall
- Check for TypeScript errors
- Review build logs

### Deployment Fails
- Check deployment credentials
- Verify build output exists
- Check server configuration
- Review deployment logs

### Site Not Loading
- Check DNS configuration
- Verify server is running
- Check SSL certificate
- Review browser console

### Authentication Issues
- Verify Firebase config
- Check auth domain
- Review security rules
- Test with different browsers

## Rollback Plan

If deployment fails:

1. **Revert to previous version**:
```bash
# Firebase Hosting
firebase hosting:rollback

# Vercel
vercel rollback

# Netlify
netlify rollback
```

2. **Restore from backup**:
- Restore Firestore data
- Restore user accounts
- Restore configuration

3. **Notify users**:
- Send notification
- Update status page
- Provide timeline

## Support Contacts

- **Firebase Support**: https://firebase.google.com/support
- **Technical Issues**: [Your contact]
- **Security Issues**: [Your contact]
- **General Questions**: [Your contact]

---

**Last Updated**: January 2026
**Version**: 1.0.0
**Status**: Production Ready ✅

