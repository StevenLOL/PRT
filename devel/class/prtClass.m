classdef prtClass < prtAction
    % prtClass   Base class for prt Classification objects
    %
    % All prtClass objects inherit all properities and methods from the
    % prtAction object. prtClass objects have the following additional
    % properties:
    % 
    %   isNativeMary - Whather or not the classifier natively produces an
    %                  M-ary result.
    %
    %   internalDecider - An optionl property, the default is empty.
    %                   InternalDecider is an instance of a prtDecision 
    %                   object. When set, the RUN function of the 
    %                   classifier will output discrete values
    %                   corresponding to the class determined by the 
    %                   classifier and the decision object
    %                   (binary classifier), or a binary vector of
    %                   zeros and ones (M-ary classification).
    %
    %   prtClass objects have the following methods:
    %
    %   plot          - Plot the output confidence of a trained classifier.
    %                   This function only operates when trained by a
    %                   dataset of 3 dimensions or lower.
    %
    %   A prtClass object inherits the TRAIN, RUN, CROSSVALIDATE and KFOLDS
    %   functions from the prtAction object.
    %
    %
    %   See also prtClassLogisticDiscriminant, prtClassBagging,
    %   prtClassMap, prtClassFld, prtClassBinaryToMaryOneVsAll, prtClassDlrt,
    %   prtClassPlsda, prtClassFld, prtClassRvm, prtClassGlrt,  prtClassSvm,
    %   prtClassTreeBaggingCap, prtClassKmsd, prtClassKnn
    %
    %
    
    %
    %   Sub-classing prtClass:
    %       Concrete sub-classes of prtClass must define the abstract
    %   methods trainAction and runAction defined in prtAction.  These
    %   methods have function definitions as follows:
    %
    %       Obj = trainAction(Obj, DataSet)
    %       DataSet = runAction(Obj, DataSet)
    %
    %   Both methods are protected and hidden.  A concrete subclass of
    %   prtClass should contain code similar to the following:
    %
    %
    %     methods (Access = protected, Hidden = true)
    %         function Obj = trainAction(Obj, DataSet)
    %           %Code to set trained parameters of Obj
    %           
    %         end
    %
    %         function DataSetOut = runAction(Obj, DataSet)
    %           %Code to run trained Obj on DataSet and generate DataSetOut
    %           %with observations set to the output of the classification
    %           %algorithm
    %
    %         end
    %     end
    %
    %
    
    properties (SetAccess=private, Abstract)
        isNativeMary % Logical, classifier natively produces an output for each unique class
    end
    
    properties
        twoClassParadigm = 'binary';   %  Whether the classifier retures one output (binary) or two outputs (m-ary) when there are only two unique class labels
    end
    
    properties (SetAccess=protected, Hidden = true)
        yieldsMaryOutput = nan; % Determined in trainProcessing()
    end
    
    properties (Dependent)
        internalDecider  % Optional prtDecider object for making decisions
    end
    
    properties (SetAccess = private, GetAccess = private, Hidden=true)
        internalDeciderDepHelper = [];
    end
    
    properties (SetAccess = protected)
        isSupervised = true;  % True
    end
    
    properties (Dependent = true, Access = 'protected', Hidden = true)
        includesDecision   
    end
    
    properties (Hidden = true)
        plotOptions = prtClass.initializePlotOptions();
    end
    
    methods (Hidden = true)
        function featureNames = updateFeatureNames(obj,featureNames)
            if ~obj.includesDecision
                for i = 1:length(featureNames)
                    featureNames{i} = sprintf('%s Output_{%d}',obj.nameAbbreviation,i);
                end
            else
                featureNames{1} = 'Class Label';
            end
        end
    end    
    
    methods
        function obj = prtClass()
            % As an action subclass we must set the properties to reflect
            % our dataset requirements
            obj.classTrain = 'prtDataSetClass';
            obj.classRun = 'prtDataSetStandard';
            obj.classRunRetained = true;
        end
        function val = get.internalDecider(obj)
            val = obj.internalDeciderDepHelper;
        end
        function obj = set.internalDecider(obj,val)
            if ~isempty(val) && ~isa(val,'prtDecision')
                error('prtClass:internalDecider','internalDecider must be an empty vector ([]) of type prtDecision, but input is a %s',class(val));
            end
            
            if ~isempty(val) && ~val.isTrained && obj.isTrained
                % We are adding a non-trained decision to a trained
                % classifier if we have verboseStorage = true we can train
                % the decider. If we don't we have to untrain and warn
                
                if ~isempty(obj.dataSet)
                    % We have the dataset
                    obj.internalDeciderDepHelper = val;
                    obj = postTrainProcessing(obj, obj.dataSet);
                    obj.yieldsMaryOutput = false;
                else
                    %Make obj.isTrained false:
                    obj.isTrained = false;
                    %warn user?
                    warning('prt:internalDecider:isTrained','Setting the internalDecider property of a prtClass object with an un-trained internalDecider sets the prtClass object''s isTrained to false');
                end
            else
                obj.internalDeciderDepHelper = val;
            end
            
        end
        function has = get.includesDecision(obj)
            has = ~isempty(obj.internalDecider);
        end
        
        function varargout = plot(Obj)
            % PLOT  Plot the output confidence of a prtClass object
            % 
            %   OBJ.plot() plots the output confidence of a prtClass
            %   object. This function only operates when the dimensionality
            %   of dataset is 3 or less. When verboseStorage is set to
            %   'true', the training data points are also displayed on the
            %   plot.
            %  
            %   See also: prtClass\explore()
            
            assert(Obj.isTrained,'Classifier must be trained before it can be plotted.');
            assert(Obj.dataSetSummary.nFeatures < 4, 'nFeatures in the training dataset must be less than or equal to 3');
            
            if Obj.yieldsMaryOutput
                if ~isempty(Obj.dataSet)
                    warning('prt:prtClass:plot:autoDecision','prtClass.plot() requires a binary prtClass or a prtClass with an internal decider. A prtDecisionMap has been trained and set as the internalDecider to enable plotting.');
                else
                    error('prt:prtClass:plot','prtClass.plot() requires a binary prtClass or a prtClass with an internal decider. A prtDecisionMap cannot be trained and set as the internalDecider to enable plotting because this classifier object does not have verboseStorege turned on and therefore the dataSet used to train the classifier is unknow. To enable plotting, set an internalDecider and retrain the classifier.');
                end
                Obj.internalDecider = prtDecisionMap;
            end
           
            HandleStructure = plotBinaryClassifierConfidence(Obj); % This handles both the binary classifier confidence plot and binary and m-ary decision plots.
           
            if ~isempty(Obj.dataSet) && ~isempty(Obj.dataSet.name)
                title(sprintf('%s (%s)',Obj.name,Obj.dataSet.name));
            else
                title(Obj.name);
            end
            varargout = {};
            if nargout > 0
                varargout = {HandleStructure};
            end
        end
        
        function Obj = set.twoClassParadigm(Obj,val)
            assert(ischar(val),'twoClassParadigm must be a string that is ''binary'' or ''mary''');
            assert(ismember(lower(val),{'binary','mary','m-ary'}),'twoClassParadigm must be either ''binary'' or ''mary');
            Obj.twoClassParadigm = lower(val);
        end
    end

    methods (Hidden = true)
        function explore(Obj)
            % explore() Explore the decision contours of classifiers
            % operating on high dimensional data.
            %   
            % Examples:
            %   ds = prtDataGenIris;
            %   t = train(prtClassMap('internalDecider',prtDecisionMap),ds);
            %   explore(t);
            %
            %   ds = catFeatures(prtDataGenUnimodal,prtDataGenBimodal);
            %   t = train(prtClassLibSvm,ds);
            %   explore(t)
            
            
            assert(~isempty(Obj.isTrained),'explore() is only for trained classifiers.');
            assert(~isempty(Obj.dataSet),'explore() requires that verboseStorage is true and therefore a prtDataSet is stored within the classifier.');
            if Obj.yieldsMaryOutput
                Obj = trainAutoDecision(Obj);
            end
            
            prtPlotUtilClassExploreGui(Obj)
        end
        
        function varargout = plotBinaryConfidenceWithFixedFeatures(Obj,freeDims,featureValues)
            
            assert(Obj.isTrained,'plotWithFixedFeatures requires a trained classifier.');
            assert(~Obj.yieldsMaryOutput,'plotWithFixedFeatures is currently only for classifiers that return a single decision statistic');
            assert(numel(freeDims)==2 || numel(freeDims)==3,'Two or three freeDims must be specified.')
            
            if length(featureValues) == Obj.dataSetSummary.nFeatures
                featureValues = featureValues(setdiff(1:Obj.dataSetSummary.nFeatures,freeDims));
            else
                assert(numel(featureValues) == (Obj.dataSetSummary.nFeatures-length(freeDims)),'Invalid feature values specified.');
            end
            
            [linGrid,gridSize] = prtPlotUtilGenerateGrid(Obj.dataSetSummary.lowerBounds(freeDims), Obj.dataSetSummary.upperBounds(freeDims), Obj.plotOptions.nSamplesPerDim);
            
            XLinGrid = nan(size(linGrid,1), Obj.dataSetSummary.nFeatures);
            XLinGrid(:,freeDims) = linGrid;
            XLinGrid(:,setdiff(1:Obj.dataSetSummary.nFeatures,freeDims)) = repmat(featureValues(:)',size(linGrid,1),1);
            
            OutputDataSet = run(Obj,prtDataSetClass(XLinGrid));
            
            if Obj.dataSetSummary.nClasses > 2
                %internalDeciders output the right colors:
                imageHandle = prtPlotUtilPlotGriddedEvaledClassifier(OutputDataSet.getObservations(), linGrid, gridSize, prtPlotUtilLightenColors(Obj.plotOptions.colorsFunction(Obj.dataSetSummary.nClasses)));
            else
                imageHandle = prtPlotUtilPlotGriddedEvaledClassifier(OutputDataSet.getObservations(), linGrid, gridSize, Obj.plotOptions.twoClassColorMapFunction());
            end
            
            HandleStructure.imageHandle = imageHandle;
            
            if ~isempty(Obj.dataSet) && ~isempty(Obj.dataSet.name)
                title(sprintf('%s (%s)',Obj.name,Obj.dataSet.name));
            else
                title(Obj.name);
            end
            varargout = {};
            if nargout > 0
                varargout = {HandleStructure};
            end
        end
        
        function produceMaryOutput = determineMaryOutput(ClassObj,DataSet)
            % Determine if an Mary output will be provided by the classifier
            % Determined by the dataSet the classifier capabilities and the            
            % twoClassParadigm switch
            if nargin ~= 2 || ~isa(DataSet,'prtDataSetBase')
                error('prt:prtClass:determineMaryOutput:invalidInput','Invalid input.');
            end
            produceMaryOutput = false; % Default answer only do mary in special conditions
            
            if DataSet.isMary
                % You have Mary data so you want an Mary output
                if ClassObj.isNativeMary
                    % You have Mary data and an Mary Classifier
                    % so you want an Mary output
                    produceMaryOutput = true;
                else
                    % Binary only classifier with Mary Data
                    error('prt:prtClass:classifierDataSetMismatch','M-ary classification is not supported by this classifier. You will need to use prtClassBinaryToMaryOneVsAll() or an equivalent M-ary emulation classifier.');
                end
            elseif DataSet.isBinary && ClassObj.isNativeMary
                % You have binary data and an Mary Classifier
                % We must check twoClassParadigm to see what you want
                produceMaryOutput = ~strcmpi(ClassObj.twoClassParadigm, 'binary');
            end % Unary Data -> false
            
            if ClassObj.includesDecision
                produceMaryOutput = false;
            end
        end
    end
    methods (Access = protected, Hidden = true)

        function Obj = postTrainProcessing(Obj,DataSet)
            if ~isempty(Obj.internalDecider)
                tempObj = Obj;
                tempObj.internalDecider = [];
                yOut = tempObj.run(DataSet);
                Obj.internalDecider = Obj.internalDecider.train(yOut);
            end
        end
        
        function ClassObj = preTrainProcessing(ClassObj, DataSet)
            % Overload preTrainProcessing() so that we can determine mary
            % output status
            ClassObj.yieldsMaryOutput = determineMaryOutput(ClassObj,DataSet);
            
            ClassObj = preTrainProcessing@prtAction(ClassObj,DataSet);
        end
        
        function OutputDataSet = postRunProcessing(ClassObj, InputDataSet, OutputDataSet)
            % Overload postRunProcessing (from prtAction) so that we can
            % enforce twoClassParadigm
            
            if ~isempty(ClassObj.internalDecider)
                OutputDataSet = ClassObj.internalDecider.run(OutputDataSet);
            end
            
            if ~isempty(ClassObj.yieldsMaryOutput) && ~isnan(ClassObj.yieldsMaryOutput)
                if ClassObj.yieldsMaryOutput
                    % Mary classifier output mary decision statistics
                    % enforce that it has output one for each class in the
                    % training data set.
                    assert(OutputDataSet.nFeatures == ClassObj.dataSetSummary.nClasses,'M-ary classifiers must yield observations with nFeatures equal to the number of unique classes in the training data set. This classifier must be modified to output observations with the proper dimensionality. If integer outputs are desired, output a binary matrix.');
                else
                    % Run Function provided mary output but ClassObj knows
                    % not to supply this. We must run
                    % maryOutput2binaryOutput()
                    OutputDataSet = maryOutput2binaryOutput(ClassObj,OutputDataSet);
                end
            end
            
            OutputDataSet = postRunProcessing@prtAction(ClassObj, InputDataSet, OutputDataSet);
        end
        
        function OutputDataSet = maryOutput2binaryOutput(ClassObj,OutputDataSet) %#ok
            % Default method to convert an Mary output to a Binary output 
            % Can/should be overloaded by classifiers
            
            % The default just takes the last (right-most) output dimension
            % In classifiers this will typically be the confidence of the
            % class with the highest valued target index.
            OutputDataSet = OutputDataSet.setObservations(OutputDataSet.getObservations(:,end));
        end
                        
        % Plotting functions
        function [OutputDataSet, linGrid, gridSize] = runClassifierOnGrid(Obj, upperBounds, lowerBounds)
            
            if nargin < 3 || isempty(lowerBounds)
                lowerBounds = Obj.dataSetSummary.lowerBounds;
            end
            
            if nargin < 2 || isempty(upperBounds)
                upperBounds = Obj.dataSetSummary.upperBounds;
            end
            
            [linGrid, gridSize] = prtPlotUtilGenerateGrid(upperBounds, lowerBounds, Obj.plotOptions.nSamplesPerDim);
            OutputDataSet = run(Obj,prtDataSetClass(linGrid));
        end
        
        function HandleStructure = plotBinaryClassifierConfidence(Obj)
            
            [OutputDataSet, linGrid, gridSize] = runClassifierOnGrid(Obj);
            
            if Obj.dataSetSummary.nClasses > 2
                %internalDeciders* output the right colors:
                imageHandle = prtPlotUtilPlotGriddedEvaledClassifier(OutputDataSet.getObservations(), linGrid, gridSize, prtPlotUtilLightenColors(Obj.plotOptions.colorsFunction(Obj.dataSetSummary.nClasses)),Obj);
            else
                imageHandle = prtPlotUtilPlotGriddedEvaledClassifier(OutputDataSet.getObservations(), linGrid, gridSize, Obj.plotOptions.twoClassColorMapFunction(),Obj);
            end
            
            if ~isempty(Obj.dataSet)
                hold on;
                handles = plot(Obj.dataSet);
                hold off;
                HandleStructure.Axes = struct('imageHandle',{imageHandle},'handles',{handles});
            else
                HandleStructure.Axes = struct('imageHandle',{imageHandle},'handles',{[]});
            end
        end
    end
    
    methods (Static, Hidden = true)
        function plotOptions =initializePlotOptions()
            plotOptions = prtOptionsGet('prtOptionsClassPlot');
        end
    end
end