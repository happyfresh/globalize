module Globalize
  module ActiveRecord
    class Translation < ::ActiveRecord::Base
      class_attribute :cache_store, :cache_expires_in

      validates :locale, :presence => true

      class << self
        # Sometimes ActiveRecord queries .table_exists? before the table name
        # has even been set which results in catastrophic failure.
        def table_exists?
          table_name.present? && super
        end

        def with_locales(*locales)
          # Avoid using "IN" with SQL queries when only using one locale.
          locales = locales.flatten.map(&:to_s)
          locales = locales.first if locales.one?
          where :locale => locales
        end
        alias with_locale with_locales

        def translated_locales
          with_cache(:translated_locales) do
            select('DISTINCT locale').order(:locale).map(&:locale)
          end
        end

        protected
          def with_cache(key, &block)
            return yield unless cache_store.present?
            cache_store.fetch([name.underscore, key], expires_in: cache_expires_in) do
              yield
            end
          end
      end

      def locale
        _locale = read_attribute :locale
        _locale.present? ? _locale.to_sym : _locale
      end

      def locale=(locale)
        write_attribute :locale, locale.to_s
      end
    end
  end
end

# Setting this will force polymorphic associations to subclassed objects
# to use their table_name rather than the parent object's table name,
# which will allow you to get their models back in a more appropriate
# format.
#
# See http://www.ruby-forum.com/topic/159894 for details.
Globalize::ActiveRecord::Translation.abstract_class = true
Globalize::ActiveRecord::Translation.cache_store = Rails.cache if defined?(Rails)
Globalize::ActiveRecord::Translation.cache_expires_in = 1.hours
