# Surveillance

## Dependencies

- LiveScript
- avconv
- ImageMagick

## Setup

```
npm install
git submodule update --init
git submodule foreach npm install
cp settings_sample.json settings.json
lsc -c index.ls
```

### Update

```
git pull && npm install && git submodule update && git submodule foreach npm install && lsc -c index.ls
```
