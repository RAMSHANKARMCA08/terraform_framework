moved {
  from = aws_lb.this
  to   = module.alb.aws_lb.this
}

moved {
  from = aws_lb_target_group.this
  to   = module.alb.aws_lb_target_group.this
}

moved {
  from = aws_lb_listener.http
  to   = module.alb.aws_lb_listener.http
}

moved {
  from = aws_lb_listener.https
  to   = module.alb.aws_lb_listener.https
}
