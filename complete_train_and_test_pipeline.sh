#!bin/bash

if [ -z "$1" ]
   then
      echo "ERROR: Train file not specified."
      exit
fi

if [ -z "$2" ]
   then
      echo "ERROR: Dev file not specified."
      exit
fi

if [ -z "$3" ]
   then
      echo "ERROR: Test file not specified."
      exit
fi

if [ -z "$4" ]
   then
      echo "ERROR: Language not specified."
      exit
fi

if [ -z "$5" ]
   then
      echo "ERROR: Loss not specified."
      exit
fi

INPUT_FILE=$1
FEATURE_FILE='data/train.feature'
GRAPH_FILE='data/train.graph'

DEV_INPUT_FILE=$2
DEV_FEATURE_FILE='data/dev.feature'
DEV_GRAPH_FILE='data/dev.graph'

TEST_INPUT_FILE=$3
TEST_FEATURE_FILE='data/test.feature'
TEST_GRAPH_FILE='data/test.graph'
TEST_PRED_FILE='data/test.pred'
TEST_DEC_FILE='data/test.dec'

ALGORITHM=fourway_lstm
LANGUAGE=$4
LOSS=$5

MODEL_PATH=models/$ALGORITHM'.model'

PYTHON_COMMAND="python3"
DEVICE="cpu"

$PYTHON_COMMAND code/processing/ref_to_graph.py --infile $INPUT_FILE --outfile $GRAPH_FILE
$PYTHON_COMMAND code/processing/ref_to_graph.py --infile $DEV_INPUT_FILE --outfile $DEV_GRAPH_FILE

$PYTHON_COMMAND code/featurization/featurize.py --infile $INPUT_FILE --outfile $FEATURE_FILE --language $LANGUAGE
$PYTHON_COMMAND code/featurization/featurize.py --infile $DEV_INPUT_FILE --outfile $DEV_FEATURE_FILE --language $LANGUAGE

THEANO_FLAGS='floatX=float32,warn_float64=raise,optimizer_including=local_remove_all_assert,device='$DEVICE

#TRAIN:
$PYTHON_COMMAND code/parsing/train.py --features $FEATURE_FILE --sentences $GRAPH_FILE --dev_features $DEV_FEATURE_FILE --dev_sentences $DEV_GRAPH_FILE --model_path $MODEL_PATH --algorithm $ALGORITHM --loss $LOSS

rm -rf $GRAPH_FILE
rm -rf $DEV_GRAPH_FILE
rm -rf $FEATURE_FILE
rm -rf $DEV_FEATURE_FILE

$PYTHON_COMMAND code/processing/ref_to_graph.py --infile $TEST_INPUT_FILE --outfile $TEST_GRAPH_FILE
$PYTHON_COMMAND code/featurization/featurize.py --infile $TEST_INPUT_FILE --outfile $TEST_FEATURE_FILE --language $LANGUAGE

#Predict:
$PYTHON_COMMAND code/parsing/predict.py --features $TEST_FEATURE_FILE --sentences $TEST_GRAPH_FILE --model_path $MODEL_PATH --algorithm $ALGORITHM --outfile $TEST_PRED_FILE

#Decode:
$PYTHON_COMMAND code/decoding/decode.py --infile $TEST_PRED_FILE --outfile $TEST_DEC_FILE --verbose

echo ""
echo "UAS: "

#Evaluate
$PYTHON_COMMAND code/evaluation/score.py --gold $TEST_INPUT_FILE --prediction $TEST_DEC_FILE
