# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     OneTime.Repo.insert!(%OneTime.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias OneTime.Accounts

# Create a demo user (optional, for development only)
if Mix.env() == :dev do
  case Accounts.create_user(%{
         email: "demo@onetimesecret.com",
         username: "demo",
         password: "Password123!"
       }) do
    {:ok, user} ->
      IO.puts("Created demo user: #{user.email}")

    {:error, changeset} ->
      IO.puts("Failed to create demo user: #{inspect(changeset.errors)}")
  end
end
