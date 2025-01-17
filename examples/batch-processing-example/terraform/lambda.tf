//load job infrastructure info from json file
data "external" "jobInfo" {
  program = [
    "python3",
    "${path.module}/../provide_job_info.py",
  ]

  query = {
    path = "../src/main/resources/jobInfo.json"
  }
}

provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}

resource "aws_s3_bucket" "batch-mapperOutputBucket" {
  bucket        = "${data.external.jobInfo.result.mapperOutputBucket}"
  force_destroy = true
}

resource "aws_s3_bucket" "batch-reducerOutputBucket" {
  bucket        = "${data.external.jobInfo.result.reducerOutputBucket}"
  force_destroy = true
}

resource "aws_iam_role" "batch-iamForLambda" {
  name = "batch-iamForLambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "batch-lambdaAccessAttachment" {
  name = "batch-lambdaAccessAttachment"

  roles = [
    "${aws_iam_role.batch-iamForLambda.name}",
  ]

  policy_arn = "arn:aws:iam::aws:policy/AWSLambdaFullAccess"
}

resource "aws_iam_policy_attachment" "batch-s3AccessAttachment" {
  name = "batch-s3AccessAttachment"

  roles = [
    "${aws_iam_role.batch-iamForLambda.name}",
  ]

  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_lambda_function" "batch-mappers_driver" {
  filename         = "../target/job.jar"
  function_name    = "${data.external.jobInfo.result.mappersDriverFunctionName}"
  role             = "${aws_iam_role.batch-iamForLambda.arn}"
  handler          = "fr.d2si.ooso.mappers_driver.MappersDriver"
  source_code_hash = "${base64sha256(file("../target/job.jar"))}"
  runtime          = "java8"
  memory_size      = "1536"
  timeout          = "300"

  environment {
    variables {
      SMR_STAGE = "PROD"
    }
  }
}

resource "aws_lambda_function" "batch-reducers_driver" {
  filename         = "../target/job.jar"
  function_name    = "${data.external.jobInfo.result.reducersDriverFunctionName}"
  role             = "${aws_iam_role.batch-iamForLambda.arn}"
  handler          = "fr.d2si.ooso.reducers_driver.ReducersDriver"
  source_code_hash = "${base64sha256(file("../target/job.jar"))}"
  runtime          = "java8"
  memory_size      = "1536"
  timeout          = "300"

  environment {
    variables {
      SMR_STAGE = "PROD"
    }
  }
}

resource "aws_lambda_function" "batch-mapper" {
  filename         = "../target/job.jar"
  function_name    = "${data.external.jobInfo.result.mapperFunctionName}"
  role             = "${aws_iam_role.batch-iamForLambda.arn}"
  handler          = "fr.d2si.ooso.mapper_wrapper.MapperWrapper"
  source_code_hash = "${base64sha256(file("../target/job.jar"))}"
  runtime          = "java8"
  memory_size      = "${data.external.jobInfo.result.mapperMemory}"
  timeout          = "300"

  environment {
    variables {
      SMR_STAGE = "PROD"
    }
  }
}

resource "aws_lambda_function" "batch-reducer" {
  filename         = "../target/job.jar"
  function_name    = "${data.external.jobInfo.result.reducerFunctionName}"
  role             = "${aws_iam_role.batch-iamForLambda.arn}"
  handler          = "fr.d2si.ooso.reducer_wrapper.ReducerWrapper"
  source_code_hash = "${base64sha256(file("../target/job.jar"))}"
  runtime          = "java8"
  memory_size      = "${data.external.jobInfo.result.reducerMemory}"
  timeout          = "300"

  environment {
    variables {
      SMR_STAGE = "PROD"
    }
  }
}

resource "aws_lambda_function" "batch-mappersListener" {
  filename         = "../target/job.jar"
  function_name    = "${data.external.jobInfo.result.mappersListenerFunctionName}"
  role             = "${aws_iam_role.batch-iamForLambda.arn}"
  handler          = "fr.d2si.ooso.mappers_listener.MappersListener"
  source_code_hash = "${base64sha256(file("../target/job.jar"))}"
  runtime          = "java8"
  memory_size      = "1536"
  timeout          = "300"

  environment {
    variables {
      SMR_STAGE = "PROD"
    }
  }
}

resource "aws_lambda_function" "batch-reducersListener" {
  filename         = "../target/job.jar"
  function_name    = "${data.external.jobInfo.result.reducersListenerFunctionName}"
  role             = "${aws_iam_role.batch-iamForLambda.arn}"
  handler          = "fr.d2si.ooso.reducers_listener.ReducersListener"
  source_code_hash = "${base64sha256(file("../target/job.jar"))}"
  runtime          = "java8"
  memory_size      = "1536"
  timeout          = "300"

  environment {
    variables {
      SMR_STAGE = "PROD"
    }
  }
}
