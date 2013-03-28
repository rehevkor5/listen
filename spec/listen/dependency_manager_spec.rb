require 'spec_helper'

describe Listen::DependencyManager do
  let(:dependency) { Listen::DependencyManager::Dependency.new('listen', '~> 0.0.1') }

  subject { Class.new { extend Listen::DependencyManager } }

  before { described_class.clear_loaded }

  describe '.add_loaded' do
    it 'adds a dependency to the list of loaded dependencies' do
      subject.dependency(dependency.name, dependency.version)
      described_class.add_loaded(dependency)
      described_class.already_loaded?(dependency).should be_true
    end
  end

  describe '.already_loaded?' do
    it 'returns false when a dependency is not in the list of loaded dependencies' do
      described_class.already_loaded?(dependency).should be_false
    end

    it 'returns true when a dependency is in the list of loaded dependencies' do
      described_class.add_loaded dependency
      described_class.already_loaded?(dependency).should be_true
    end
  end

  describe '.clear_loaded' do
    it 'clears the whole list of loaded dependencies' do
      described_class.add_loaded dependency
      described_class.already_loaded?(dependency).should be_true
      described_class.clear_loaded
      described_class.already_loaded?(dependency).should be_false
    end
  end

  describe '#dependency' do
    it 'registers a new dependency for the managed class' do
      subject.dependency(dependency.name, dependency.version)
      subject.dependencies_loaded?.should be_false
    end
  end

  describe '#load_dependencies' do
    before { subject.dependency(dependency.name, dependency.version) }

    context 'when dependencies can be loaded' do
      before { subject.stub(:gem, :require) }

      it 'loads all the registerd dependencies' do
        subject.load_dependencies
        subject.dependencies_loaded?.should be_true
      end
    end

    context 'when dependencies can not be loaded' do
      it 'raises an error' do
        expect {
          subject.load_dependencies
        }.to raise_error(described_class::Error)
      end

      context 'when running under bundler' do
        before { subject.should_receive(:running_under_bundler?).and_return(true) }

        it 'includes the Gemfile declaration to satisfy the dependency' do
          begin
            subject.load_dependencies
          rescue described_class::Error => e
            e.message.should include("gem '#{dependency.name}', '#{dependency.version}'")
          end
        end
      end

      context 'when not running under bundler' do
        before { subject.should_receive(:running_under_bundler?).and_return(false) }

        it 'includes the command to install the dependency' do
          begin
            subject.load_dependencies
          rescue described_class::Error => e
            e.message.should include("gem install #{dependency.name} --version '#{dependency.version}'")
          end
        end
      end
    end
  end

  describe '#dependencies_loaded?' do
    it 'return false when dependencies are not loaded' do
      subject.dependency(dependency.name, dependency.version)
      subject.dependencies_loaded?.should be_false
    end

    it 'return true when dependencies are loaded' do
      subject.stub(:gem, :require)

      subject.dependency(dependency.name, dependency.version)
      subject.load_dependencies
      subject.dependencies_loaded?.should be_true
    end

    it 'return true when there are no dependencies to load' do
      subject.dependencies_loaded?.should be_true
    end
  end
end
