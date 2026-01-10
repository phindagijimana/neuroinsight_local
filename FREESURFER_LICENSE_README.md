# FreeSurfer License Setup

**Required for MRI processing functionality**

## Get License

1. Visit: https://surfer.nmr.mgh.harvard.edu/registration.html
2. Register with research email
3. Download `license.txt` file

## Install License

Place `license.txt` in the NeuroInsight project root directory.

```
neuroinsight_local/
├── license.txt    ← Place license here
├── README.md
└── ...
```

## Verify

```bash
./neuroinsight license  # Should show license valid
./neuroinsight start    # Start NeuroInsight
# Upload MRI file and verify real processing results
```

**Without license:** Processing fails silently, shows mock/placeholder data.

## Troubleshooting

**License not recognized:**
- Ensure file is named exactly `license.txt`
- Verify it's in NeuroInsight project root
- Check file permissions: `chmod 644 license.txt`

**Still not working:**
- Restart services: `./neuroinsight stop && ./neuroinsight start`
- Check logs: `docker-compose logs freesurfer`
- Re-download license from FreeSurfer website

## Support

- FreeSurfer: https://surfer.nmr.mgh.harvard.edu/fswiki/FreeSurferSupport
- Check logs: `cat neuroinsight.log`

---

© 2025 University of Rochester. All rights reserved.
