export function formattedSchedule(start, end) {
  const startMoment = moment(start);
  const endMoment = moment(end);
  return `${startMoment.format("LT")} - ${endMoment.format(
    "LT"
  )}, ${startMoment.format("Do MMMM, Y")}`;
}
