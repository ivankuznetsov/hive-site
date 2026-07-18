# frozen_string_literal: true

require_relative "../lib/honeycomb_catalog_sync"

Jekyll::Hooks.register :site, :after_init do |site|
  snapshot_path = File.join(site.source, "_data", "honeycombs.json")
  HoneycombCatalogSync.validate_payload!(File.binread(snapshot_path))
rescue HoneycombCatalogSync::Error, SystemCallError, IOError => e
  details = e.respond_to?(:errors) ? e.errors.join("; ") : e.message
  raise Jekyll::Errors::FatalException, "Honeycomb catalog snapshot is invalid: #{details}"
end
