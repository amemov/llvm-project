; RUN: opt -passes=loop-vectorize,dce,instcombine -mtriple aarch64-linux-gnu -mattr=+sve \
; RUN:   -prefer-predicate-over-epilogue=scalar-epilogue < %s -S | FileCheck %s


target datalayout = "e-m:e-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128"
target triple = "aarch64-unknown-linux-gnu"

define void @cmpsel_i32(ptr noalias nocapture %a, ptr noalias nocapture readonly %b, i64 %n) {
; CHECK-LABEL: @cmpsel_i32(
; CHECK-NEXT:  entry:
; CHECK:       vector.body:
; CHECK:         [[WIDE_LOAD:%.*]] = load <vscale x 4 x i32>, ptr {{.*}}, align 4
; CHECK-NEXT:    [[TMP1:%.*]] = icmp eq <vscale x 4 x i32> [[WIDE_LOAD]], zeroinitializer
; CHECK-NEXT:    [[TMP2:%.*]] = select <vscale x 4 x i1> [[TMP1]], <vscale x 4 x i32> splat (i32 2), <vscale x 4 x i32> splat (i32 10)
; CHECK:         store <vscale x 4 x i32> [[TMP2]], ptr {{.*}}, align 4
;
entry:
  br label %for.body

for.body:                                         ; preds = %entry, %for.body
  %indvars.iv = phi i64 [ 0, %entry ], [ %indvars.iv.next, %for.body ]
  %arrayidx = getelementptr inbounds i32, ptr %b, i64 %indvars.iv
  %0 = load i32, ptr %arrayidx, align 4
  %tobool.not = icmp eq i32 %0, 0
  %cond = select i1 %tobool.not, i32 2, i32 10
  %arrayidx2 = getelementptr inbounds i32, ptr %a, i64 %indvars.iv
  store i32 %cond, ptr %arrayidx2, align 4
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  %exitcond.not = icmp eq i64 %indvars.iv.next, %n
  br i1 %exitcond.not, label %for.end.loopexit, label %for.body, !llvm.loop !0

for.end.loopexit:                                 ; preds = %for.body
  br label %for.end

for.end:                                          ; preds = %for.end.loopexit, %entry
  ret void
}

define void @cmpsel_f32(ptr noalias nocapture %a, ptr noalias nocapture readonly %b, i64 %n) {
; CHECK-LABEL: @cmpsel_f32(
; CHECK-NEXT:  entry:
; CHECK:       vector.body:
; CHECK:         [[WIDE_LOAD:%.*]] = load <vscale x 4 x float>, ptr {{.*}}, align 4
; CHECK-NEXT:    [[TMP1:%.*]] = fcmp ogt <vscale x 4 x float> [[WIDE_LOAD]], splat (float 3.000000e+00)
; CHECK-NEXT:    [[TMP2:%.*]] = select <vscale x 4 x i1> [[TMP1]], <vscale x 4 x float> splat (float 1.000000e+01), <vscale x 4 x float> splat (float 2.000000e+00)
; CHECK:         store <vscale x 4 x float> [[TMP2]], ptr {{.*}}, align 4

entry:
  br label %for.body

for.body:                                         ; preds = %entry, %for.body
  %indvars.iv = phi i64 [ 0, %entry ], [ %indvars.iv.next, %for.body ]
  %arrayidx = getelementptr inbounds float, ptr %b, i64 %indvars.iv
  %0 = load float, ptr %arrayidx, align 4
  %cmp1 = fcmp ogt float %0, 3.000000e+00
  %conv = select i1 %cmp1, float 1.000000e+01, float 2.000000e+00
  %arrayidx3 = getelementptr inbounds float, ptr %a, i64 %indvars.iv
  store float %conv, ptr %arrayidx3, align 4
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  %exitcond.not = icmp eq i64 %indvars.iv.next, %n
  br i1 %exitcond.not, label %for.end, label %for.body, !llvm.loop !0

for.end:                                          ; preds = %for.body, %entry
  ret void
}

define void @fneg_f32(ptr noalias nocapture %a, ptr noalias nocapture readonly %b, i64 %n) {
; CHECK-LABEL: @fneg_f32(
; CHECK-NEXT:  entry:
; CHECK:       vector.body:
; CHECK:         [[WIDE_LOAD:%.*]] = load <vscale x 4 x float>, ptr {{.*}}, align 4
; CHECK-NEXT:    [[TMP1:%.*]] = fneg <vscale x 4 x float> [[WIDE_LOAD]]
; CHECK:         store <vscale x 4 x float> [[TMP1]], ptr {{.*}}, align 4

entry:
  br label %for.body

for.body:                                         ; preds = %entry, %for.body
  %indvars.iv = phi i64 [ 0, %entry ], [ %indvars.iv.next, %for.body ]
  %arrayidx = getelementptr inbounds float, ptr %b, i64 %indvars.iv
  %0 = load float, ptr %arrayidx, align 4
  %fneg = fneg float %0
  %arrayidx3 = getelementptr inbounds float, ptr %a, i64 %indvars.iv
  store float %fneg, ptr %arrayidx3, align 4
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  %exitcond.not = icmp eq i64 %indvars.iv.next, %n
  br i1 %exitcond.not, label %for.end, label %for.body, !llvm.loop !0

for.end:                                          ; preds = %for.body, %entry
  ret void
}

!0 = distinct !{!0, !1, !2, !3, !4, !5}
!1 = !{!"llvm.loop.mustprogress"}
!2 = !{!"llvm.loop.vectorize.width", i32 4}
!3 = !{!"llvm.loop.vectorize.scalable.enable", i1 true}
!4 = !{!"llvm.loop.interleave.count", i32 1}
!5 = !{!"llvm.loop.vectorize.enable", i1 true}
