# encoding: utf-8
require 'infoboxer/parser'

module Infoboxer
  describe Parser, 'inline markup' do
    let(:ctx){Parser::Context.new(source)}
    let(:parser){Parser.new(ctx)}

    let(:nodes){parser.inline}
    subject{nodes}

    context 'when just text' do
      let(:source){'just text'}
      
      it{should == [Tree::Text.new('just text')]}
    end

    context 'text with entities' do
      let(:source){'just textin&apos; with &Omega; symbol'}

      its(:'first.text'){should == "just textin' with \u{03A9} symbol"}
    end

    context 'when italic' do
      context 'simple' do
        let(:source){"''italic''"}
        
        it{should == [Tree::Italic.new(Tree::Text.new('italic'))]}
      end

      context 'auto-closing of markup' do
        let(:source){"''italic"}
        
        it{should == [Tree::Italic.new(Tree::Text.new('italic'))]}
      end
    end

    context 'when bold' do
      let(:source){"'''bold'''"}
      
      it{should == [Tree::Bold.new(Tree::Text.new('bold'))]}
    end

    context 'when bold italic' do
      let(:source){"'''''bold italic'''''"}
      
      it{should == [Tree::BoldItalic.new(Tree::Text.new('bold italic'))]}
    end

    context 'when wikilink' do
      subject{nodes.first}
      
      context 'with label' do
        let(:source){'[[Argentina|Ar]]'}

        it{should be_a(Tree::Wikilink)}
        its(:link){should == 'Argentina'}
        its(:children){should == [Tree::Text.new('Ar')]}
      end

      context 'with formatted label' do
        let(:source){"[[Argentina|Argentinian ''Republic'']]"}

        it{should be_a(Tree::Wikilink)}
        its(:link){should == 'Argentina'}
        its(:"children.count"){should == 2}
      end

      context 'without label' do
        let(:source){'[[Argentina]]'}

        it{should be_a(Tree::Wikilink)}
        its(:link){should == 'Argentina'}
        its(:children){should == [Tree::Text.new('Argentina')]}
      end
    end

    context 'when external link' do
      subject{nodes.first}
      
      context 'with label' do
        let(:source){'[http://google.com Google]'}

        it{should be_a(Tree::ExternalLink)}
        its(:link){should == 'http://google.com'}
        its(:children){should == [Tree::Text.new('Google')]}
      end

      context 'without caption' do
        let(:source){'[http://google.com]'}

        it{should be_a(Tree::ExternalLink)}
        its(:link){should == 'http://google.com'}
        its(:children){should == [Tree::Text.new('http://google.com')]}
      end

      context 'not a link at all' do
        let(:source){'[just text]'}

        it{should be_a(Tree::Text)}
        its(:text){should == '[just text]'}
      end

      context 'not a link: complex inline' do
        let(:source){"This ''is [just text], trust'' me"}
        subject{nodes.find(Tree::Italic).first}

        its(:text){should == 'is [just text], trust'}
      end

      context 'unclosed formatting inside' do
        # found at https://en.wikipedia.org/wiki/List_of_sovereign_states#Transnistria
        let(:source){"[http://google.com ''Google]"}

        it{should be_a(Tree::ExternalLink)}
        its(:link){should == 'http://google.com'}
        its(:children){should == [Tree::Italic.new(Tree::Text.new('Google'))]}
      end
    end

    context 'when HTML' do
      subject{nodes.first}
      
      context 'paired' do
        let(:source){'<strike>Some text</strike>'}

        it{should be_a(Tree::HTMLTag)}
        its(:tag){should == 'strike'}
        its(:children){should == [Tree::Text.new('Some text')]}
      end

      context 'with attributes' do
        let(:source){'<strike class="airstrike" style="color: red;">Some text</strike>'}

        it{should be_a(Tree::HTMLTag)}
        its(:tag){should == 'strike'}
        its(:children){should == [Tree::Text.new('Some text')]}
        its(:attrs){should ==
          {class: 'airstrike', style: 'color: red;'}
        }
      end

      context 'self-closing' do
        let(:source){'<br/>'}

        it{should be_a(Tree::HTMLTag)}
        its(:tag){should == 'br'}
        its(:children){should be_empty}
      end

      context 'self-closing with attrs' do
        let(:source){'<div name=totalpop/>'}
        it{should be_a(Tree::HTMLTag)}
        its(:children){should be_empty}
        its(:attrs){should == {name: 'totalpop'}}
      end

      context 'lonely opening' do
        let(:source){'<strike>Some text'}

        it{should be_a(Tree::HTMLOpeningTag)}
        its(:tag){should == 'strike'}
      end

      context 'lonely closing' do
        let(:source){'</strike>'}

        it{should be_a(Tree::HTMLClosingTag)}
        its(:tag){should == 'strike'}
      end

      context 'br' do
        let(:source){'<br> test'}

        it{should be_a(Tree::HTMLTag)}
        its(:children){should be_empty}
      end
    end

    context 'when nowiki' do
      subject{nodes.first}
      let(:source){"<nowiki> all kinds <ref> of {{highly}} irrelevant '' markup </nowiki>"}

      it{should == Tree::Text.new(" all kinds <ref> of {{highly}} irrelevant '' markup ")}
    end

    describe 'sequence' do
      subject{nodes}
      context 'plain' do
        let(:source){"This is '''bold''' text with [[Some link|Link]]"}

        it 'should be parsed!' do
          expect(subject.count).to eq 4
          expect(subject.map(&:class)).to eq [Tree::Text, Tree::Bold, Tree::Text, Tree::Wikilink]
          expect(subject.map(&:text)).to eq ['This is ', 'bold', ' text with ', 'Link']
        end
      end

      context 'html + template' do
        let(:source){'<br>{{small|(Sun of May)}}'}
        it 'should be parsed!' do
          expect(subject.count).to eq 2
          expect(subject.first).to be_kind_of(Tree::HTMLTag)
          expect(subject.last).to be_kind_of(Tree::Template)
        end
      end

      context 'text + html' do
        let(:source){'test <b>me</b>'}
        it 'should be parsed!' do
          expect(subject.count).to eq 2
          expect(subject.map(&:class)).to eq [Tree::Text, Tree::HTMLTag]
        end
      end

      context 'text, ref, template' do
        let(:source){'4D S.A.S.<ref>{{Citation | url = http://www.4D.com | title = 4D}}</ref>'}
        it 'should be parsed!' do
          expect(subject.count).to eq 2
          expect(subject.map(&:class)).to eq [Tree::Text, Tree::Ref]
        end

        context 'even in "short" context' do
          let(:source){'4D S.A.S.<ref>{{Citation | url = http://www.4D.com | title = 4D}}</ref>'}
          subject{parser.short_inline}
          it 'should be parsed!' do
            expect(subject.count).to eq 2
            expect(subject.map(&:class)).to eq [Tree::Text, Tree::Ref]
          end
        end
      end
    end

    describe 'nesting' do
      context 'simple' do
        let(:source){"'''[[Bold link|Link]]'''"}
        subject{Parser.inline(source).first}

        it{should be_kind_of(Tree::Bold)}
        its(:"children.first"){should be_kind_of(Tree::Wikilink)}
      end

      context 'when cross-sected inside template' do
        let(:source){"''italic{{tmpl|its ''italic'' too}}''"}
        
        its(:count){should == 1}
        its(:'first.text'){should == 'italic'}
        its(:'first.children.count'){should == 2}
      end
    end
  end
end
