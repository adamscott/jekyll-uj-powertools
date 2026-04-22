# Limit Collections Generator
# Limits the number of documents in collections during development for faster builds
#
# Usage in _config.dev.yml:
#   limit_collections:
#     recipes: 50
#     products: 20
#
# By default, uses a seeded random sample for diverse selection across categories.
# To disable randomization and take first N documents:
#   limit_collections:
#     recipes: 50
#     products: 20
#     randomize: false
#
# Run Jekyll with: bundle exec jekyll serve --config _config.yml,_config.dev.yml

module Jekyll
  class LimitCollectionsGenerator < Generator
    safe true
    priority :highest  # Run before other generators

    def generate(site)
      limits = site.config['limit_collections']
      return unless limits.is_a?(Hash)

      # Check if randomization is disabled (default: true)
      randomize = limits.fetch('randomize', true)

      limits.each do |collection_name, limit|
        # Skip the 'randomize' option itself
        next if collection_name == 'randomize'

        limit_sort = 'ascending'

        if limit.is_a?(Hash)
            if limit['sort'] == 'descending'
                limit_sort = 'descending'
            end
            limit = limit['count']
        end

        next unless limit.is_a?(Integer) && limit > 0

        collection = site.collections[collection_name]
        next unless collection

        original_count = collection.docs.size
        next if original_count <= limit

        if randomize
          # Use a seeded random for repeatable but diverse sampling
          # Seed based on collection name so it's consistent across rebuilds
          rng = Random.new(collection_name.hash.abs)
          sampled_docs = collection.docs.shuffle(random: rng).first(limit)
          collection.docs.replace(sampled_docs)
          Jekyll.logger.info "LimitCollections:", "Limited '#{collection_name}' from #{original_count} to #{limit} documents (random sample)"
        else
          # Take first N documents in order
          collection_docs_method = limit_sort === "ascending" ? :first : :last

          collection.docs.replace(collection.docs.send(collection_docs_method, limit))
          Jekyll.logger.info "LimitCollections:", "Limited '#{collection_name}' from #{original_count} to #{limit} documents"
        end
      end
    end
  end
end

