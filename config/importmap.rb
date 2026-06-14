# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "barcode-detector", to: "https://esm.sh/barcode-detector@2?bundle"
pin "tesseract.js", to: "https://cdn.jsdelivr.net/npm/tesseract.js@5/dist/tesseract.esm.min.js"
