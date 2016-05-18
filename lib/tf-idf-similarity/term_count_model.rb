# A simple document-term matrix.
module TfIdfSimilarity
  class TermCountModel
    include MatrixMethods

    # The documents in the corpus.
    attr_reader :documents
    # The set of terms in the corpus.
    attr_reader :terms
    # The average number of tokens in a document.
    attr_reader :average_document_size

    # @param [Array<Document>] documents documents
    # @param [Hash] opts optional arguments
    # @option opts [Symbol] :library :gsl, :narray, :nmatrix or :matrix (default)
    def initialize(documents, opts = {})
      @documents = documents
      @terms = Hash.new
      documents.each do |document|
        document.terms.each do |term|
          term_info = @terms[term] || [@terms.size, 0]
          @terms[term] = [term_info.first, term_info.last + 1]
        end
      end

      @library = (opts[:library] || :matrix).to_sym

      array = Array.new(terms.size) { Array.new(documents.size, 0) }
      documents.each_index do |j|
        document = documents[j]
        document.term_counts.each do |term_count|
          i = term_index(term_count.first)
          array[i][j] = term_count.last
        end
      end

      @matrix = initialize_matrix(array)
      @average_document_size = documents.empty? ? 0 : sum / column_size.to_f
    end

    # @param [String] term a term
    # @return [Integer] index of the term in list all terms
    def term_index(term)
      term_info = terms[term]
      term_info ? term_info.first : nil
    end

    # @param [String] term a term
    # @return [Integer] the number of documents the term appears in
    def document_count(term)
      term_info = terms[term]
      term_info ? term_info.last : 0
    end

    # @param [String] term a term
    # @return [Integer] the number of times the term appears in the corpus
    def term_count(term)
      index = term_index(term)
      if index
        case @library
        when :gsl, :narray
          row(index).sum
        when :nmatrix
          row(index).each.reduce(0, :+) # NMatrix's `sum` method is slower
        else
          vector = row(index)
          unless vector.respond_to?(:reduce)
            vector = vector.to_a
          end
          vector.reduce(0, :+)
        end
      else
        0
      end
    end
  end
end
