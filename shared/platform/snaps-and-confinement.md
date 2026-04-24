# Snaps And Confinement

Apps on ctrlX OS are packaged as snaps.

Key implications:

- filesystem access is restricted by confinement
- AppArmor denials may be expected
- service lifecycle is managed through snap services
- path assumptions from standard Linux software often need adaptation for snap layouts and writable data areas
