require 'spec_helper'

module TfIdfSimilarity
  describe TfIdfModel do
    let :text do
      "FOO-foo BAR bar \r\n\t 123 !@#"
    end

    let :tokens do
      ['FOO-foo', 'BAR', 'bar', "\r\n\t", '123', '!@#']
    end

    let :document_without_text do
      Document.new('')
    end

    let :document do
      Document.new(text)
    end

    let :document_with_tokens do
      Document.new(text, :tokens => tokens)
    end

    let :document_with_term_counts do
      Document.new(text, :term_counts => {'bar' => 5, 'baz' => 10})
    end

    let :non_corpus_document do
      Document.new('foo foo foo')
    end

    def similarity_matrix_values(model)
      matrix = model.similarity_matrix
      if MATRIX_LIBRARY == :nmatrix
        matrix.each.to_a
      else
        matrix.to_a.flatten
      end
    end

    context 'without documents', :empty_matrix => true do
      let :model do
        TfIdfModel.new([], :library => MATRIX_LIBRARY)
      end

      describe '#documents' do
        it 'should be empty' do
          model.documents.should be_empty
        end
      end

      describe '#document_index' do
        it 'should return nil' do
          model.document_index(document).should be_nil
        end
      end

      describe '#text_index' do
        it 'should return nil' do
          model.text_index(text).should be_nil
        end
      end

      describe '#terms' do
        it 'should be empty' do
          model.terms.should be_empty
        end
      end

      describe '#inverse_document_frequency' do
        it 'should return negative infinity' do
          model.idf('foo').should == -1/0.0 # -Infinity
        end
      end

      describe '#term_frequency' do
        it 'should return the term frequency' do
          model.tf(document, 'foo').should == Math.sqrt(2)
        end
      end

      describe '#term_frequency_inverse_document_frequency' do
        it 'should return negative infinity' do
          model.tfidf(document, 'foo').should == -1/0.0 # -Infinity
        end
      end

      describe '#similarity_matrix' do
        it 'should be empty' do
          similarity_matrix_values(model).should be_empty
        end
      end
    end

    context 'with documents' do
      let :documents do
        [
          document,
          document_with_tokens,
          document_without_text,
          document_with_term_counts,
        ]
      end

      let :model do
        TfIdfModel.new(documents, :library => MATRIX_LIBRARY)
      end

      describe '#documents' do
        it 'should return the documents' do
          model.documents.should == documents
        end
      end

      describe '#document_index' do
        it 'should return the index' do
          model.document_index(document).should == 0
        end
      end

      describe '#text_index' do
        it 'should return the index' do
          model.text_index(text).should == 0
        end
      end

      describe '#terms' do
        it 'should return the terms' do
          model.terms.to_a.sort.should == [["bar", [1, 3]], ["baz", [3, 1]], ["foo", [0, 1]], ["foo-foo", [2, 1]]]
        end
      end

      describe '#inverse_document_frequency' do
        it 'should return the inverse document frequency' do
          model.idf('foo').should be_within(0.001).of(1 + Math.log(4 / (1 + 1.0)))
        end

        it 'should return the inverse document frequency of a non-occurring term' do
          model.idf('xxx').should be_within(0.001).of(1 + Math.log(4 / (0 + 1.0)))
        end
      end

      describe '#term_frequency' do
        it 'should return the term frequency if no tokens given' do
          model.tf(document, 'foo').should == Math.sqrt(2)
        end

        it 'should return the term frequency if tokens given' do
          model.tf(document_with_tokens, 'foo-foo').should == 1
        end

        it 'should return no term frequency if no text given' do
          model.tf(document_without_text, 'foo').should == 0
        end

        it 'should return the term frequency if term counts given' do
          model.tf(document_with_term_counts, 'bar').should == Math.sqrt(5)
        end

        it 'should return the term frequency of a non-occurring term' do
          model.tf(document, 'xxx').should == 0
        end

        it 'should return the term frequency in a non-occurring document' do
          model.tf(non_corpus_document, 'foo').should == Math.sqrt(3)
        end
      end

      describe '#term_frequency_inverse_document_frequency' do
        it 'should return the tf*idf' do
          model.tfidf(document, 'foo').should be_within(0.001).of((1 + Math.log(4 / (1 + 1.0))) * Math.sqrt(2))
        end

        it 'should return the tf*idf of a non-occurring term' do
          model.tfidf(document, 'xxx').should == 0
        end

        it 'should return the tf*idf in a non-occurring term' do
          model.tfidf(non_corpus_document, 'foo').should be_within(0.001).of((1 + Math.log(4 / (1 + 1.0))) * Math.sqrt(3))
        end
      end

      describe '#similarity_matrix' do
        it 'should return the similarity matrix' do
          expected = [
            1.0,   0.326, 0.0, 0.195,
            0.326, 1.0,   0.0, 0.247,
            0.0,   0.0,   0.0, 0.0,
            0.195, 0.247, 0.0, 1.0,
          ]

          similarity_matrix_values(model).each_with_index do |value,i|
            value.should be_within(0.001).of(expected[i])
          end
        end
      end
    end
  end
end
